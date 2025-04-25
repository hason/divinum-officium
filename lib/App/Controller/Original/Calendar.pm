use utf8;


# notes for kalendar: bissectal, nigra19
sub note {
  my ($note) = shift;
  my %comm = %{setupstring($lang1, 'Psalterium/Comment.txt')};
  my $output = '<TR><TD COLSPAN="5" ALIGN="LEFT">';
  $output .= setfont('1', $comm{"$note note"}) . '</TD></TR>';
}

1;
