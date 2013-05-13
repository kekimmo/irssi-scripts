
use strict;
use warnings;

use Irssi;

our $VERSION = '0.01';
our %IRSSI = (
  authors     => 'Kimmo Kenttälä',
  contact     => 'kimmo@kenttala.fi',
  name        => 'Urit',
  description => 'URI tracker - Right now, all it does is color new URIs green',
  license     => 'Undecided',
);


my %uri_hash = ();


sub find_uris {
  my $text = shift;

  my @uris = $text =~ m{(
    (?:http|https)
    ://
    \S+
    )}gx;

  return @uris;
}


sub log_uris {
  my ($server, $target, $origin, $text) = @_;
  my @uris = find_uris($text);
  foreach my $uri (@uris) {
    if (!exists($uri_hash{$uri})) {
      $uri_hash{$uri} = { 'count' => 0, 'origins' => [] };
    }
    $uri_hash{$uri}{'count'} += 1;
    # Origin information not used, don't bother keeping it
    #push($uri_hash{$uri}{'origins'}, $origin);
  }
}


sub format_uris {
  my $text = shift;
  my @uris = find_uris($text);
  foreach my $uri (@uris) {
    if (exists($uri_hash{$uri})) {
      my $count = $uri_hash{$uri}->{'count'};
      if ($count == 1) {
        my $uri_re_quoted = quotemeta($uri);
        my $replacement = sprintf("\cC3%s\cC", $uri);
        $text =~ s/${uri_re_quoted}(?=\s|$)/$replacement/g;
      }
    }
  }
  return $text;
}


sub sig_message_public {
  my ($server, $msg, $nick, $address, $target) = @_;
  log_uris($server, $target, { 'type' => 'user', 'nick' => $nick }, $msg);
}


sub sig_message_own_public {
  my ($server, $msg, $target) = @_;
  log_uris($server, $target, { 'type' => 'me' }, $msg);
}


sub sig_print_text {
  my ($text_dest, $text, $stripped_text) = @_;
  $text = format_uris($text);
  Irssi::signal_continue($text_dest, $text, $stripped_text);
}


sub cmd_urit {
  my ($data, $server, $witem) = @_;
  if (%uri_hash) {
    my @rows = map(
      sprintf("%4d \cC1\cC%s", $uri_hash{$_}->{'count'}, $_),
      sort(keys(%uri_hash)));
    Irssi::print(join("\n  ", ("Logged URIs:", @rows)), MSGLEVEL_CLIENTCRAP);
  }
}


Irssi::signal_add_last('message public', \&sig_message_public);
Irssi::signal_add_last('message own_public', \&sig_message_own_public);
Irssi::signal_add_first('print text', \&sig_print_text);
Irssi::command_bind('urit', \&cmd_urit);

