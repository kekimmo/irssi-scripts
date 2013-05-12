
use strict;
use warnings;

use Irssi;

our $VERSION = '0.01';
our %IRSSI = (
  authors     => 'Kimmo Kenttälä',
  contact     => 'kimmo@kenttala.fi',
  name        => 'Urit',
  description => 'URI tracker',
  license     => 'Undecided',
);


my %uri_counts = ();


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
  my $text = shift;
  ++$uri_counts{$_} foreach find_uris($text);
}


sub format_uris {
  my $text = shift;
  my @uris = find_uris($text);
  foreach my $uri (@uris) {
    if (exists($uri_counts{$uri})) {
      my $count = $uri_counts{$uri};
      my $uri_quoted = quotemeta($uri);
      my $replacement = sprintf('%s (%d)', $uri, $count);
      $text =~ s/$uri_quoted/$replacement/g;
    }
  }
  return $text;
}


sub sig_message_public {
  my ($server, $msg, $nick, $address, $target) = @_;
  log_uris($msg);
}


sub sig_message_own_public {
  my ($server, $msg, $target) = @_;
  log_uris($msg);
}


sub sig_print_text {
  my ($text_dest, $text, $stripped_text) = @_;
  $text = format_uris($text);
  Irssi::signal_continue($text_dest, $text, $stripped_text);
}


sub cmd_urit {
  my ($data, $server, $witem) = @_;
  if (%uri_counts) {
    my @rows = map(
      sprintf('%4d %s', $uri_counts{$_}, $_),
      sort(keys(%uri_counts)));
    Irssi::print(join("\n  ", ("Logged URIs:", @rows)), MSGLEVEL_CLIENTCRAP);
  }
}


Irssi::signal_add_last('message public', \&sig_message_public);
Irssi::signal_add_last('message own_public', \&sig_message_own_public);
Irssi::command_bind('urit', \&cmd_urit);


