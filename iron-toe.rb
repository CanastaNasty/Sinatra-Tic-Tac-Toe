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

def drawB(ar)
	ar.each_slice(3).map do |row|
		row.join "|"
	end.join "\n---+---+---\n"
end

n = params[:move].to_i
game = params
if game["board"][n] != " X " && game["board"][n] != " O " && game["won"] == false
	game["board"][n] = " #{game["player"]} "
	game["turn"] += 1
end
game["won"] = checkWin(game["board"])
game["player"] = whichP(game["turn"])
game["table"] = drawB(game["board"])