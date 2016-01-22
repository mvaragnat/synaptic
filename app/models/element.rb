class Element < ActiveRecord::Base

  validates :address, presence: :true, uniqueness: :true

  def send_to_watson
    #Saving element to watson corpus
    url_watson = "https://gateway.watsonplatform.net/concept-insights/api/v2/corpora/#{ENV['WATSON_ACCOUNT']}/#{ENV['WATSON_CORPUS']}/documents/doc#{self.id}"
    puts "send to watson"
    puts url_watson
    resp_watson = HTTP.basic_auth(:user => ENV['WATSON_USERNAME'], :pass => ENV['WATSON_PASSWORD'])
        .post(url_watson,
          :json => {
            :label => self.title,
            :parts => [{
              "content-type" => "text/plain",
              "name" => "summary",
              :data => self.summary
            },
            {
              "content-type" => "text/html",
              "name" => "content",
              :data => self.content
            }],
            "user_fields" => {
                :address => self.address
              }
          })

    return self.check_response resp_watson
  end

  def update_from_readability
    #query of the page text
    #use Readability API

    #other possible option: query the whole page and parse using mozilla lib
    #https://github.com/mozilla/readability

    address_readability = self.get_address_readability
    puts address_readability

    resp_readability = HTTP.get(address_readability)

    puts "Update element from Readability"
    puts resp_readability.code
    puts resp_readability.reason

    unless resp_readability.code == 200
      puts "error with Readability"
      return "error with Readability"
    end

    resp_readability_json = JSON.parse(resp_readability.to_s.force_encoding('UTF-8'))
    title = HTMLEntities.new.decode(resp_readability_json["title"])
    puts "title"
    puts title
    summary = HTMLEntities.new.decode(resp_readability_json["excerpt"])
    puts "summary"
    puts summary
    content = ActionView::Base.full_sanitizer.sanitize(
                HTMLEntities.new.decode(
                  resp_readability_json["content"]
                )
              ).strip

    self.update_attributes(title: title, summary: summary, content: content)

    #content is not saved in the element
    return content
  end

  def update_from_readability_and_send_to_watson
    #shortcut function
    self.update_from_readability
    resp_watson = self.send_to_watson

    return self.check_response resp_watson
  end

  #-------------------
  #Utilities

  def check_response(response)
    puts "code watson"
    puts response.code
    puts response.reason

    unless response.code == 201 || response.code == 200
      puts "error watson #{JSON.parse(response)}"
    end

    return response
  end

  def get_address_readability
    #URL needs to be formatted a bit to be accepted by Readability

    address_readability = "https://readability.com/api/content/v1/parser?url=";
    token = "&token=#{ENV['READABILITY_TOKEN']}";
    if self.address.include?("#")
      parties = self.address.split("#");
      address_readability += parties[0] + token + "#" + parties[1];
    else
      address_readability += self.address + token;
    end

    return address_readability
  end

  #Watson methods to get concepts quickly out of a text
  def self.annotate_text(content)
    url_watson = "https://gateway.watsonplatform.net/concept-insights/api/v2/graphs/wikipedia/en-20120601/annotate_text"
    response = HTTP.basic_auth(:user => ENV['WATSON_USERNAME'], :pass => ENV['WATSON_PASSWORD'])
      .headers("content-type" => "text/plain")
      .post(url_watson,
            :json => {
                "body" => content
              })

    puts "code watson annotate text"
    puts response.code
    puts response.reason

    unless response.code == 201 || response.code == 200
      puts "error #{JSON.parse(response)}"
    end

    return response
  end
end
