# Synaptic
## AI-based content discovery based on [IBM's Watson Concept Insights API](http://www.ibm.com/smarterplanet/us/en/ibmwatson/developercloud/concept-insights.html)

Share a blog post, an interesting article, a page from Medium or Quora. Synaptic will understand the concepts discussed and share back TED Talks, articles shared by other people, and Wikipedia pages.

You can test it live on [Synaptic hosted app](http://synaptic.herokuapp.com/), where the content already shared by many people will make the results more interesting.

It is a Ruby on Rails app that can be deployed, for example, on Heroku. It does not require to be hosted on IBM's Bluemix, as it hits the API endpoints from HTTP requests.

## How it works

1) This app is intended to demo the potential of the API, building upon and going further than IBM's [demo](https://concept-insights-demo.mybluemix.net/). Instead of inputting a body of text, we require only a link to a webpage, and use Readability's Parser API to get the main text of the page.

2) The body of text is analyzed using Concept Insights "annotate_text" endpoint for fast performance. It extracts concepts, and the top 3 concepts are used to fetch documents (this number can be configured in an environment variable).

3) Two requests are made, one against a corpus of previously-submitted articles, and another one against a public corpus of TED talks, using the "conceptual_search" API call.

4) The articles, TED talks, and Wikipedia pages derived from the concepts, are presented to the user.

5) Lastly, the article is submitted to Watson to be added to the corpus for future searches.

## Configuration

Synaptic needs a few configuration steps to work. Basically you need to open a Watson account and a Readability account.

1) Start with [creating a Bluemix account](https://console.ng.bluemix.net/catalog/services/concept-insights/) and activating an instance of the Concept Insights service.

2) From the Bluemix console, open the instance. In "Service Credentials" (you may have to create a new set of credentials if they don't already exists), get your username and password

3) Use this curl command to get your concept insights account ID (replace USERNAME and PASSWORD)

```
curl -u USERNAME:PASSWORD 'https://gateway.watsonplatform.net/concept-insights/api/v2/accounts'
```

4) Use this curl command to get create to concept insights corpus - one for tests and development, and one for production (replace USERNAME, PASSWORD, ACCOUNT by their values, and choose a name for CORPUS)

```
curl -u USERNAME:PASSWORD -X PUT -d '{"access":"private'}' 'https://gateway.watsonplatform.net/concept-insights/api/v2/corpora/ACCOUNT/CORPUS'
```

5) Create a Readability account and get your [Readability Parser API](https://www.readability.com/developers/api/parser) token

6) In /config, create an application.yml file that looks like this (figaro gem is already bundled) :

```
READABILITY_TOKEN: XXXXXXXXXXXXXXXX
WATSON_USERNAME: XXXXX-XXXXX-XXXXX-XXXXX-XXXXX
WATSON_PASSWORD: XXXXX
WATSON_ACCOUNT: XXXXX
MAX_CONCEPTS: "3"

production:
  WATSON_CORPUS: XXXXX

development:
  WATSON_CORPUS: XXXXX
```

7) If you deployed to Heroku, use to set the environment variables

```
$ figaro heroku:set -e production
```

## Author
[Matthieu Varagnat](https://twitter.com/MVaragnat)

## Licence
Shared under [MIT licence](http://choosealicense.com/licenses/mit/)

