# Colorize a text output with the given color if.
# <tt>text</tt> The text to colorize.
# <tt>color_code</tt> The color code string to set
# <tt>color</tt> Does not color if false. Defaults to ($arguments && $arguments[:colorize])
def colorize(text, color_code, color = $colorize)
  color ? "#{color_code}#{text}\e[0m" : text
end

# Draw a red line of text
def red(text, color = $colorize)
  colorize(text, "\e[31m", color)
end

# Draw a Green line of text
def green(text, color = $colorize)
  colorize(text, "\e[32m", color)
end

# Draw a Yellow line of text
def yellow(text, color = $colorize)
  colorize(text, "\e[33m", color)
end

# Draw a Yellow line of text
def blue(text, color = $colorize)
  colorize(text, "\e[34m", color)
end

def white(text, color = $colorize)
  colorize(text, "\e[37m", color)
end


#STYLE = {
#      :default    =>    “33[0m”,
#       # styles
#       :bold       =>    “33[1m”,
#       :underline  =>    “33[4m”,
#       :blink      =>    “33[5m”,
#       :reverse    =>    “33[7m”,
#       :concealed  =>    “33[8m”,
#      # font colors
#       :black      =>    “33[30m”,
#       :red        =>    “33[31m”,
#       :green      =>    “33[32m”,
#       :yellow     =>    “33[33m”,
#       :blue       =>    “33[34m”,
#       :magenta    =>    “33[35m”,
#       :cyan       =>    “33[36m”,
#       :white      =>    “33[37m”,
#       # background colors
#       :on_black   =>    “33[40m”,
#       :on_red     =>    “33[41m”,
#       :on_green   =>    “33[42m”,
#       :on_yellow  =>    “33[43m”,
#       :on_blue    =>    “33[44m”,
#       :on_magenta =>    “33[45m”,
#       :on_cyan    =>    “33[46m”,
#       :on_white   =>    “33[47m” }
#