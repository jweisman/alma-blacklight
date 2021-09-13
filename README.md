# Alma Blacklight

A sample application showing a [Blacklight](http://projectblacklight.org) deployment over [Ex Libris Alma](http://www.exlibrisgroup.com/category/AlmaOverview). 

Introduction
------------
This repository builds on a vanilla Blacklight deployment to add features based on support for [third party discovery](https://developers.exlibrisgroup.com/alma/integrations/discovery) systems in Alma.

## Features

### Harvest repository
To populate the Blacklight Solr index, a rake task called `oai_harvest` is provided. The task stores its last run date to enable incremental harvesting.

### Real Time Availability
When search results are displayed, a call to the [Get BIBs](https://developers.exlibrisgroup.com/alma/apis/bibs) Alma REST API is performed with all of the returned document IDs and the `d_avail` flag. Availability is indicated by the color of the physical and online buttons.

### Fulfillment Options
Fulfillment options (such as location information, request options, full text availability) are provided using the Alma services page. The services page can be accessed by clicking on the availability buttons.

### Authentication
This repository is integrated with the Alma Social Authentication feature. Users are taken to the Alma social login screen to authenticate and then redirected back to Blacklight where a user session is created. Once logged in, fulfillment options appropriate to the authenticated user are displayed. Details from Alma are displayed on the user information page.

## Installation

1. Clone this repository: `git clone https://github.com/jweisman/alma-blacklight.git`
2. Install dependencies: `bundle install`
3. Copy the `application.example.yml` file to `application.yml` and replace the placeholder values.
4. Run the rake task to populate the index: `rake oai_harvest`
5. Run the application: `bin\rails server` for WEBrick 

License
-------
The code for these samples is made available under the [MIT license](http://opensource.org/licenses/MIT).