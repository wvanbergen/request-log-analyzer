require 'spec_helper'

class DummyInheritedFromRails3 < RequestLogAnalyzer::FileFormat::Rails3
end

describe DummyInheritedFromRails3 do

  subject { RequestLogAnalyzer::FileFormat.load(DummyInheritedFromRails3) }

  it { should be_well_formed }
  it { should have(11).report_trackers }

end
