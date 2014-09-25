require 'mechanize'
require 'terminal-table'

NFL_URL = "#{ENV['NFL_URL']}"
NFL_PWD = "#{ENV['NFL_PWD']}"
NFL_LOGIN = "#{ENV['NFL_LOGIN']}"
NFL_PP = "#{ENV['NFL_PP']}"

class NFLFantasyScraper

	def initialize
		@mechanize = Mechanize.new
	end

	def login
		login_page = @mechanize.get(NFL_URL)
		form = @mechanize.page.forms.first

		form.field_with(:name => "username").value = NFL_LOGIN
		form.field_with(:name => "password").value = NFL_PWD

		page = form.submit form.buttons.first
		@page = @mechanize.get(NFL_PP)
	end

	def print_table
		rows = []
		my_team.each do |player|
			rows << [player[0], player[1][0], player[1][1]]
		end
		table = Terminal::Table.new :headings => ['Player', 'Opponent', 'Current Points'], :rows => rows
	end

	def my_team
		Hash[my_team_player_names.zip(join_stats)]
	end

	def my_team_player_names
		team_page = @mechanize.get(NFL_URL)

		players = team_page.search('.tableType-player .playerNameAndInfo').map do |td|
		  td.text.split(' ')[0..1].join(' ')
		end
		players - [" ", nil, "Offense", "Defense Team", "Kicker"]
	end

	def scrape_opponents
		team_page = @mechanize.get(NFL_URL)

		opponents = team_page.search('.tableType-player .playerOpponent').map do |td|
			td.text
		end
		opponents - [" ", nil, "Opp"]
	end

	def scrape_points
		team_page = @mechanize.get(NFL_URL)

		points = team_page.search('.tableType-player .statTotal').map do |td|
			td.text
		end
		points - [" ", nil, "Points"]
	end

	def available_players
		players = []

		players << add_available_players
		next_page
		players << add_available_players
		next_page
		players << add_available_players

		players.flatten - [" ", nil]
	end

	private

	def join_stats
		scrape_opponents.zip(scrape_points)
	end

	def next_page
		link = @page.link_with(text: '>')
		@page = link.click
	end

	def add_available_players
		@page.search('.tableType-player .playerNameAndInfo').map do |td|
			if td.text != "Player"
		  	td.text.split(' ')[0..1].join(' ')
		  end
		end
	end

end

scraper = NFLFantasyScraper.new
scraper.login
puts scraper.print_table
