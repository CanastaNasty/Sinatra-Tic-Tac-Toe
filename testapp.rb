# testapp.rb
require 'sinatra'
require 'sinatra/json'
require 'ostruct'
require 'json'
require 'pry'

enable :sessions

helpers do
	#takes an array with the states for each square and adds the formatting
	def drawB(ar)
		ar.each_slice(3).map do |row|
			row.join "|"
		end.join "\n---+---+---\n"
	end

	#checks board array for win conditions and returns the player tha won or 'false'
	def checkWin(ar)
		w = false
		lines = [[0,1,2],[3,4,5],[6,7,8],[0,3,6],[1,4,7],[2,5,8],[0,4,8],[2,4,6]]
		lines.each do |a,b,c|
			if (ar[a] == " X " || ar[a] == " O ") && ar[a] == ar[b] && ar[b] == ar[c]
				w = ar[a]
			end
		end
		return w
	end

	#determines which player's turn it is
	def whichP(t)
		if t % 2 ==0
			p = "O"
		else
			p = "X"
		end
		return p
	end
end

#array containing every game on the server
games = []

get '/favicon.ico' do
	404
end

#submits a move for a given game
post '/:game/:move' do
	n = params[:move].to_i
	id = params[:game].to_i
	game = games[id]
	if game.board[n] != "X" && game.board[n] != "O" && game.won == false
		game.board[n] = " #{game.player} "
		game.turn += 1
	end
	game.won = checkWin(game.board)
	game.player = whichP(game.turn)
	game.table = drawB(game.board)
	json game.to_h
end

#creates new game and pushes to games array
post '/' do
	newGame = OpenStruct.new
	newGame.player = "X"
	newGame.won = false
	newGame.turn = 1
	newGame.table = []
	newGame.board = []
	id = games.size
	9.times do |x|
		newGame.board.push("<button name='move' value='#{id}/#{x}'> </button>")
	end

	games.push(newGame)
	redirect to("/#{id}")
end

get '/login' do
	session[:token] = SecureRandom.hex(16)
end

get '/YOLO' do
	session[:token]
end

#shows game board without submitting a turn
get '/:game' do
	g = params[:game].to_i
	@board = games[g].board
	haml :show
end

#lobby for creating new games
get '/' do
	@game = games.size + 1
	haml :lobby
end

__END__
@@layout
%script(src="http://code.jquery.com/jquery-1.10.1.min.js")
= yield

@@show
:javascript
	$(document).ready(function() {
		$("body").on("click", "button", function() {
			$.post(this.value, function(data) {
				$(".board").html(data["table"])
				if (data.won != false){
					$(".win").html(data.won+"won!")
				};
			}, "json");
		});
	});

%body
	%p.win
	%pre.board= drawB(@board)

@@lobby
%body
	%form(method="post" action="/")
		%button(type="submit") New Game