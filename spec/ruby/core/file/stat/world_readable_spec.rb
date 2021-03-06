require File.expand_path('../../../../spec_helper', __FILE__)
require File.expand_path('../../../../shared/file/world_readable', __FILE__)
require File.expand_path('../fixtures/classes', __FILE__)

ruby_version_is "1.9" do
  describe "File::Stat.world_readable?" do
    it_behaves_like(:file_world_readable, :world_readable?, FileStat)
  end
end
