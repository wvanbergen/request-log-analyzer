=begin
index:Ej

= Ruby/ProgressBar: A Text Progress Bar Library for Ruby

Last Modified: 2005-05-22 00:28:04

--

Ruby/ProgressBar is a text progress bar library for Ruby.
It can indicate progress with percentage, a progress bar,
and estimated remaining time.

The latest version of Ruby/ProgressBar is available at 
((<URL:http://namazu.org/~satoru/ruby-progressbar/>))
.

== Examples

  % irb --simple-prompt -r progressbar
  >> pbar = ProgressBar.new("test", 100)
  => (ProgressBar: 0/100)
  >> 100.times {sleep(0.1); pbar.inc}; pbar.finish
  test:          100% |oooooooooooooooooooooooooooooooooooooooo| Time: 00:00:10
  => nil

  >> pbar = ProgressBar.new("test", 100)
  => (ProgressBar: 0/100)
  >> (1..100).each{|x| sleep(0.1); pbar.set(x)}; pbar.finish
  test:           67% |oooooooooooooooooooooooooo              | ETA:  00:00:03

== API

--- ProgressBar#new (title, total, out = STDERR)
    Display the initial progress bar and return a
    ProgressBar object.  ((|title|)) specifies the title,
    and ((|total|)) specifies the total cost of processing.
    Optional parameter ((|out|)) specifies the output IO.

    The display of the progress bar is updated when one or
    more percent is proceeded or one or more seconds are
    elapsed from the previous display.

--- ProgressBar#inc (step = 1)
    Increase the internal counter by ((|step|)) and update
    the display of the progress bar. Display the estimated
    remaining time on the right side of the bar. The counter
    does not go beyond the ((|total|)).

--- ProgressBar#set (count)
    Set the internal counter to ((|count|)) and update the
    display of the progress bar. Display the estimated
    remaining time on the right side of the bar.  Raise if
    ((|count|)) is a negative number or a number more than
    the ((|total|)).

--- ProgressBar#finish
    Stop the progress bar and update the display of progress
    bar. Display the elapsed time on the right side of the bar.
    The progress bar always stops at 100 % by the method.

--- ProgressBar#halt
    Stop the progress bar and update the display of progress
    bar. Display the elapsed time on the right side of the bar.
    The progress bar stops at the current percentage by the method.

--- ProgressBar#format=
    Set the format for displaying a progress bar.
    Default: "%-14s %3d%% %s %s".

--- ProgressBar#format_arguments=
    Set the methods for displaying a progress bar.
    Default: [:title, :percentage, :bar, :stat].

--- ProgressBar#file_transfer_mode
    Use  :stat_for_file_transfer instead of :stat to display
    transfered bytes and transfer rate.


ReverseProgressBar class is also available.  The
functionality is identical to ProgressBar but the direction
of the progress bar is just opposite.

== Limitations

Since the progress is calculated by the proportion to the
total cost of processing, Ruby/ProgressBar cannot be used if
the total cost of processing is unknown in advance.
Moreover, the estimation of remaining time cannot be
accurately performed if the progress does not flow uniformly.

== Download

Ruby/ProgressBar is a free software with ABSOLUTELY NO WARRANTY
under the terms of Ruby's license.

  * ((<URL:http://namazu.org/~satoru/ruby-progressbar/ruby-progressbar-0.9.tar.gz>))
  * ((<URL:http://cvs.namazu.org/ruby-progressbar/>))

--

- ((<Satoru Takabayashi|URL:http://namazu.org/~satoru/>)) -
=end
