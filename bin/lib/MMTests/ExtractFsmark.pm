# ExtractFsmark.pm
package MMTests::ExtractFsmark;
use MMTests::SummariseVariableops;
our @ISA = qw(MMTests::SummariseVariableops);
use strict;

sub initialise() {
	my ($self, $reportDir, $testName) = @_;
	$self->{_ModuleName} = "ExtractFsmark";
	$self->{_DataType}   = DataTypes::DATA_OPS_PER_SECOND;
        $self->{_ExactSubheading} = 1;
        $self->{_PlotType} = "simple-filter";
        $self->{_DefaultPlot} = "1";

	$self->SUPER::initialise($reportDir, $testName);
}

sub extractReport() {
	my ($self, $reportDir, $reportName, $profile) = @_;
	my ($user, $system, $elapsed, $cpu);
	my $iteration = 1;

	$self->{_CompareLookup} = {
		"files/sec" => "pdiff",
		"overhead"  => "pndiff"
	};

	my @clients;
	my @files = <$reportDir/$profile/fsmark-*.log>;
	foreach my $file (@files) {
		if ($file =~ /-cmd-/) {
			next;
		}
		$file =~ s/.log$//;
		my @split = split /-/, $file;
		push @clients, $split[-1];
	}
	@clients = sort { $a <=> $b } @clients;

	my @ops;
	foreach my $client (@clients) {
		my $file = "$reportDir/$profile/fsmark-$client.log";
		my $preamble = 1;
		my $enospace = 0;
		open(INPUT, $file) || die("Failed to open $file\n");
		while (<INPUT>) {
			my $line = $_;
			if ($preamble) {
				if ($line !~ /^FSUse/) {
					next;
				}
				$preamble = 0;
				next;
			}

			if ($line =~ /Insufficient free space/) {
				$enospace = 1;
			}

			if ($enospace) {
				next;
			}

			my @elements = split(/\s+/, $_);
			push @{$self->{_ResultData}}, [ "$client-files/sec", ++$iteration, $elements[4] ];
		}
		close INPUT;
		push @ops, "$client-files/sec";
	}

	$self->{_Operations} = \@ops;
}

1;
