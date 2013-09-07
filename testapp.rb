# testapp.rb
require 'sinatra'
require 'sinatra/json'
require 'ostruct'
require 'json'
require 'pry'
require 'mail'
require 'digest'
require 'sinatra/logger'
require 'iron_worker_ng'

set :root, '/home/david/Rails-Apps/Sinatra'

enable :sessions

helpers do
	#takes an array with the states for each square and adds the formatting
	def drawB(ar)
		ar.each_slice(3).map do |row|
			row.join "|"
		end.join "\n---+---+---\n"
	end

	#checks board array for win conditions and returns the player that won or 'false'
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

#setting Mandrill defaults for mail
Mail.defaults do 
	delivery_method :smtp, {
		port: 587,
		address: "smtp.mandrillapp.com",
		user_name: ENV["MANDRILL_USERNAME"],
		password: ENV["MANDRILL_PASSWORD"]
	}
end

#array containing every game on the server
games = []

#hash linking e-mails to session id's and passwords
users = {ENV["ADMIN_EMAIL"] => {password: Digest::SHA1.hexdigest(ENV["ADMIN_PASSWORD"]), id: SecureRandom.hex(16)}}

#array containing list of valid session_ids
ids = []

#hash containing registrations to be confirmed by e-mail
confirmations = Hash.new

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

#logins a user or creates a new user
post '/login' do
	session = OpenStruct.new
	session.email = params[:email]
	session.password = Digest::SHA1.hexdigest(params[:pword])
	session.match = false
	session.signup = false
	if users.has_key?(session.email)
		if users[session.email][:password] == session.password
			session.match = true
			session[:token] = users[session.email][:id]
		end
		logger.warn(session.match)
	else
		session.signup = true
		session.confirm = Digest::SHA1.hexdigest(session.email)
		confirmations[session.confirm] = { 
			"email" => session.email,
			value: {
				password: session.password, 
				id: SecureRandom.hex(16)
			}
		}
		address = "#{ENV["HOST_PATH"]}/confirm/#{session.confirm}"
		Mail.deliver do
			to session.email
			from ENV["ADMIN_EMAIL"]
			subject 'Welcome to Xtreme Tic-Tac-Toe'

			html_part do
				content_type 'text/html; charset=UTF-8'
				body "Confirm your registration to Xtreme Tic-Tac-Toe: <a href=#{address}>#{address}</a>"
			end
		end
	end
	json session.to_h
end

#confirms a registration
get '/confirm/:confirmation' do
	conf = params[:confirmation]
	if confirmations.has_key?(conf)
		users[confirmations[conf]["email"]] = confirmations[conf][:value]
		session[:token] = confirmations[conf][:value][:id]
		ids.push(session[:token])
		confirmations.delete(conf)
	end
	redirect to ("/")
end

#returns list of valid session ids
get '/ids' do
	json ids
end

#shows game board without submitting a turn
get '/:game' do
	g = params[:game].to_i
	@board = games[g].board
	haml :show
end

#lobby for creating new games
get '/' do
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
:javascript
	var sess = #{session[:token].to_json}

	$.fn.serializeObject = function()
		{
		    var o = {};
		    var a = this.serializeArray();
		    $.each(a, function() {
		        if (o[this.name] !== undefined) {
		            if (!o[this.name].push) {
		                o[this.name] = [o[this.name]];
		            }
		            o[this.name].push(this.value || '');
		        } else {
		            o[this.name] = this.value || '';
		        }
		    });
		    return o;
		};

	$(document).ready(function() {
		$("body").on("click", "#lsubmit", function() {
			$.post("/login", $("#login").serializeObject(), function(data) {
				if (data.match == true) {
					$(".session").html("Logged In")
				}
				else if (data.signup == true) {
					$(".session").html("Confirmation e-mail sent")
				}
				else {
					$(".error").html("Incorrect Login!")
				}
			}, "json");

		});
	});

	$.getJSON('/ids', function(data) {
		var x=$(".session");
		if (data.indexOf(sess)!=-1) {
			x.html("Logged In")
		};
	});

%body
	.error
	.session
		%form#login(method="post" action="/login")
			%p.error
			E-Mail: 
			%input(type="text" name="email")
			Password: 
			%input(type="password" name="pword")
		%button#lsubmit Log In
	%form(method="post" action="/")
		%button(type="submit") New Game
