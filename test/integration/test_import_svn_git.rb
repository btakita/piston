require File.expand_path("#{File.dirname(__FILE__)}/../test_helper")

class TestImportSvnGit < Piston::TestCase
  attr_reader :root_path, :repos_path, :wc_path

  def setup
    super
    @root_path = mkpath("/tmp/import_svn_git")
    @repos_path = @root_path + "repos"
    @wc_path = @root_path + "wc"
    mkpath(wc_path)

    Dir.chdir(wc_path) do
      git(:init)
      File.open(wc_path + "README", "wb") {|f| f.write "Hello World!"}
      (wc_path + "vendor").mkdir
      File.open(wc_path + "vendor/.gitignore", "wb") {|f| f.write "*.swp"}
      git(:add, ".")
      git(:commit, "-m", "'first commit'")
    end
  end

  def test_import
    Dir.chdir(wc_path) do
      piston :import, "http://dev.rubyonrails.org/svn/rails/plugins/ssl_requirement/", "vendor/ssl_requirement"
    end

    Dir.chdir(wc_path) do
      assert_equal %Q(# On branch master
# Changes to be committed:
#   (use "git reset HEAD <file>..." to unstage)
#
#\tnew file:   vendor/ssl_requirement/.piston.yml
#\tnew file:   vendor/ssl_requirement/README
#\tnew file:   vendor/ssl_requirement/lib/ssl_requirement.rb
#\tnew file:   vendor/ssl_requirement/test/ssl_requirement_test.rb
#
).split("\n").sort, git(:status).split("\n").sort
    end

    info = YAML.load_file(wc_path + "vendor/ssl_requirement/.piston.yml")
    assert_equal 1, info["format"]
    assert_equal "http://dev.rubyonrails.org/svn/rails/plugins/ssl_requirement/", info["repository_url"]
    assert_equal "Piston::Svn::Repository", info["repository_class"]
    assert_equal "5ecf4fe2-1ee6-0310-87b1-e25e094e27de", info["handler"][Piston::Svn::UUID]
  end
end
