local ffi = require("ffi")

local rawterm = require("lib.rawterm")

local ncursesw = ffi.load("ncursesw")

-- Colour setup stuff taken from https://www.linuxjournal.com/content/about-ncurses-colors-0

ffi.cdef([[
	// Not from ncursesw:
	char* setlocale( int category, const char* locale );
	int setenv(const char *envname, const char *envval, int overwrite);

	// cchar_t* is just represented as void* here
	// attr_t is just int

	void *initscr(void);
	void endwin(void);
	void refresh(void);
	
	int curs_set(int visibility);

	// int setcchar(void *wcval, const wchar_t *wch, const int attrs, short color_pair, const void *opts);
	int mvprintw(int y, int x, char *fmt, ...);

	int attron(int attrs);
	int attroff(int attrs);
	int wattron(void *window, int attrs);
	int wattroff(void *window, int attrs);

	int init_pair(short pair, short f, short b);
	bool has_colors(void);
	bool can_change_color(void);
	int start_color(void);

	int erase(void);
	int clear(void);

	int nodelay(void *win, bool bf);
	int noecho(void);
	int getch(void);
	int ungetch(int ch);

	int getbegx(void *win);
	int getbegy(void *win);
	int getmaxx(void *win);
	int getmaxy(void *win);
]])

local term = {}

local LC_ALL = 0 -- Apparently it's "implementation-defined", though... (TODO?)
local A_BLINK = 2 ^ (11 + 8) -- TODO: Add warning that some terminals *will* actually blink instead of settig a bright background
local A_BOLD = 2 ^ (13 + 8)
local ERR = 2 ^ 32 - 1

local colours = {
	black = 0,
	darkRed = 1,
	darkGreen = 2,
	darkYellow = 3,
	darkBlue = 4,
	darkMagenta = 5,
	darkCyan = 6,
	lightGrey = 7,
	darkGrey = 8,
	red = 9,
	green = 10,
	yellow = 11,
	blue = 12,
	magenta = 13,
	cyan = 14,
	white = 15,
}

function term.init()
	-- term.cStrMaxLen = nil
	-- term.cStr = nil

	ffi.C.setlocale(LC_ALL, "")
	ffi.C.setenv("TERM", "xterm-256color", 1)
	term.window = ncursesw.initscr()
	term.setCursor(false)
	assert(ncursesw.can_change_color() and ncursesw.has_colors(), "Colour not supported?")
	ncursesw.start_color()
	term.initColourPairs()

	rawterm.enableRawMode()
end

function term.quit()
	rawterm.disableRawMode()
	ncursesw.endwin()
end

function term.present()
	ncursesw.refresh()
end

function term.ensureCStr(length) -- length of the LuaJIT string, so not including the null terminator
	if term.cStrMaxLen and term.cStrMaxLen >= length then
		return
	end
	term.cStrMaxLen = length
	term.cStr = ffi.new("char[?]", length + 1) -- +1 to account for null terminator
end

function term.print(x, y, foregroundColour, backgroundColour, text)
	text = tostring(text)
	term.ensureCStr(#text)
	ffi.copy(term.cStr, text)

	local fg, bg = colours[foregroundColour], colours[backgroundColour]
	term.setColour(fg, bg)
	ncursesw.mvprintw(y, x, term.cStr)
	term.unsetColour(fg, bg)
end

function term.setCursor(setting)
	if not setting then
		ncursesw.curs_set(0)
	elseif setting == "high" then
		ncursesw.curs_set(2)
	else
		ncursesw.curs_set(1)
	end
end

function term.colourNum(fg, bg)
	local B = 2 ^ 7
	local bbb = bg % 8 * 2 ^ 4
	local ffff = fg % 8
	return B + bbb + ffff
end

function term.cursColour(fg)
	return fg % 8
end

function term.initColourPairs()
	for bg = 0, 7 do
		for fg = 0, 7 do
			local colourPair = term.colourNum(fg, bg)
			ncursesw.init_pair(colourPair, term.cursColour(fg), term.cursColour(bg))
		end
	end
end

function term.isBold(fg)
	return math.floor(fg / 2 ^ 3) % 2 == 1
end

function term.setColour(fg, bg)
	ncursesw.attron(term.colourNum(fg, bg) * 2 ^ 8)
	if term.isBold(fg) then
		ncursesw.attron(A_BOLD)
	end
	if term.isBold(bg) then
		ncursesw.attron(A_BLINK)
	end
end

function term.unsetColour(fg, bg)
	ncursesw.attroff(term.colourNum(fg, bg) * 2 ^ 8)
	if term.isBold(fg) then
		ncursesw.attroff(A_BOLD)
	end
	if term.isBold(bg) then
		ncursesw.attroff(A_BLINK)
	end
end

function term.clear()
	ncursesw.erase()
end

function term.getInput()
	local char = ncursesw.getch()
	if char == ERR then
		return
	end
	local success, val = pcall(string.char, char)
	if not success then
		return
	end
	return val
end

function term.getSize()
	return ncursesw.getmaxx(term.window), ncursesw.getmaxy(term.window)
end

return term
