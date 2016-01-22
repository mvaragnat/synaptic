class WatsonController < ApplicationController

  def home
  end

  def conceptual_search
    #uses annotate_search API endpoint for faster results

    @address = params[:address].strip

    #Step 1:
    #Save element in database

    element = Element.find_by(address: @address)
    if element
      puts "Element already exists"
    else
      element = Element.new(address: @address)
      if element.save
        puts "Element saved."
      else
        puts "Error when saving"
        @error = element.errors
      end
    end

    #Step 2
    #Query Readability API to fill in the fields
    content = element.update_from_readability
    @summary = element.summary
    @title = element.title

    #Step3
    #extract concepts from the text
    resp_watson = Element.annotate_text(content)

    if resp_watson.code == 200 || resp_watson.code == 201
      #puts JSON.parse(resp_watson)
      @annotations = JSON.parse(resp_watson)["annotations"]

      @concepts = Array.new
      concepts_ids = Array.new
      max_concepts = 3
      n = 0

      #concepts are sent in decreasing probability order
      #but beware - there are duplicates

      @annotations.each do |annotation|
        label = annotation['concept']['label']
        score = annotation['score']
        concept_id = annotation['concept']['id']

        #recreate Wikipedia link from concept
        address = "https://en.wikipedia.org/wiki/"
        address << concept_id.gsub("/graphs/wikipedia/en-20120601/concepts/", "")

        unless concepts_ids.include? concept_id
          @concepts.push [label, score, address]
          concepts_ids.push concept_id
          puts "concept #{label} score #{score} address #{address}"
          n +=1
        end

        break if n >= max_concepts
      end

    else
      @error = JSON.parse(resp_watson)
      puts "error watson annotate text #{@error}"
    end

    #Step 5 find related articles in your corpus using conceptual search
    document_fields = Hash.new
    document_fields["user_fields"] = 1
    document_fields["parts"] = 1

    url_watson_search = "https://gateway.watsonplatform.net/concept-insights/api/v2/corpora/#{ENV['WATSON_ACCOUNT']}/#{ENV['WATSON_CORPUS']}/conceptual_search"

    resp_watson_search = HTTP.basic_auth(:user => ENV['WATSON_USERNAME'], :pass => ENV['WATSON_PASSWORD'])
        .get(url_watson_search, :params => {
          "ids" => concepts_ids.to_json,
          "document_fields" => document_fields.to_json
          })

    puts "conceptual_search"
    @code = resp_watson_search.code
    puts @code
    puts resp_watson_search.reason

    if @code == 200
      watson_els_json = JSON.parse(resp_watson_search.to_s.force_encoding(Encoding::UTF_8))
      all_results = watson_els_json["results"]
      @results = Array.new
      n = 0
      max_results = 3
      all_results.each do |result|
        label = result['label']
        score = result['score']
        puts "Document label #{label} score #{score}"
        address = result['user_fields']['address']
        parts = result['parts']
        summary = ""
        parts.each do |part|
          #iterate to find the summary
          if part["name"] == "summary"
            summary = part["data"]
          end
        end
        @results[n] = [label, summary, score, address]
        n += 1
        break if n >= max_results
      end
    else
      @error = JSON.parse(resp_watson_search.to_s.force_encoding(Encoding::UTF_8))
      puts "error watson conceptual search #{@error}"
    end

    t5 = Time.now

    #Step6 find TED talks, again using conceptual search but on the public corpus

    url_watson_TED = "https://gateway.watsonplatform.net/concept-insights/api/v2/corpora/public/TEDTalks/conceptual_search"

    resp_watson_TED = HTTP.basic_auth(:user => ENV['WATSON_USERNAME'], :pass => ENV['WATSON_PASSWORD'])
        .get(url_watson_TED, :params => {
          "ids" => concepts_ids.to_json,
          "document_fields" => document_fields.to_json
          })

    if @code == 200
      watson_TED_json = JSON.parse(resp_watson_TED.to_s.force_encoding(Encoding::UTF_8))
      all_results = watson_TED_json["results"]
      @ted = Array.new
      n = 0
      max_results = 3
      all_results.each do |result|
        label = result['label']
        summary = result['user_fields']['description']
        score = result['score']
        puts "TED #{label} score #{score}"
        address = result['user_fields']['url']
        thumbnail = result['user_fields']['thumbnail']
        @ted[n] = [label, summary, score, address, thumbnail]
        n += 1
        break if n >= max_results
      end
    else
      @error = JSON.parse(resp_watson_TED.to_s.force_encoding(Encoding::UTF_8))
      puts "error watson conceptual search TED #{@error}"
    end
  end

  def send_element_from_address
    #callback to save the element to Watson corpus
    #to display faster the results, this is called at the end of conceptual_search.js.erb

    @address = params[:address].strip
    puts "address to be saved in Watson corpus: #{@address}"

    element = Element.find_by(address: @address)
    if element
      element.update_from_readability_and_send_to_watson
    else
      @error = "element not found"
      puts @error
    end
  end
end
