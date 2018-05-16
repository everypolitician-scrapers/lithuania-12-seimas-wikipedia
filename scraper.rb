#!/bin/env ruby
# frozen_string_literal: true

require 'pry'
require 'scraped'
require 'scraperwiki'
require 'wikidata_ids_decorator'

require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

class MembersPage < Scraped::HTML
  decorator WikidataIdsDecorator::Links

  field :members do
    member_table.xpath('.//tr[td]').map { |tr| fragment(tr => MemberRow).to_h }
  end

  private

  def member_table
    noko.xpath('//table[.//th[contains(., "Wahlbezirk")]]')
  end
end

class MemberRow < Scraped::HTML
  field :name do
    name_link.map(&:text).map(&:tidy).first
  end

  field :id do
    name_link.first&.attr('wikidata')
  end

  field :party do
    party_link.map(&:text).map(&:tidy).first
  end

  field :party_id do
    party_link.first&.attr('wikidata')
  end

  private

  def tds
    noko.css('td')
  end

  def name_link
    tds[0].css('a')
  end

  def party_link
    tds[2].css('a')
  end
end

url = 'https://de.wikipedia.org/wiki/12._Seimas'
Scraped::Scraper.new(url => MembersPage).store(:members)
