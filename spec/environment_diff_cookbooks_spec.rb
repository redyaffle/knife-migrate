require 'spec_helper'
require 'chef/knife/environment_diff_cookbooks'

describe KnifeMigrate::EnvironmentDiffCookbooks do
  let(:plugin) { described_class.new }
  let(:rest_object) { double(:rest) }

  before do
    allow(plugin).to receive(:rest).and_return(rest_object)
    allow(rest_object).to receive(:get_rest)
  end

  it 'is knife plugin' do
    banner = 'knife environment diff cookbooks --e1 [source env] --e2 [destination env]'
    expect(described_class.banner).to eq(banner)
  end

  context 'arguments validation' do
    it 'displays usage if no arguments are provided' do
      allow(plugin).to receive(:name_args).and_return([])
      expect(plugin).to receive(:show_usage)
      expect(plugin).to receive(:exit)
      plugin.validate
    end

    it 'displays usage if only one environment is provided' do
      allow(plugin).to receive(:name_args).and_return(['debug'])
      expect(plugin).to receive(:show_usage)
      expect(plugin).to receive(:exit)
      plugin.validate
    end

    it 'does not exit if argument is provided' do
      allow(plugin).to receive(:name_args).and_return(['debug', 'unstable'])
      expect(plugin).not_to receive(:show_usage)
      expect(plugin).not_to receive(:exit)
      plugin.validate
    end
  end

  it 'grabs cookbooks from environment' do
    allow(plugin).to receive(:name_args).and_return(['debug', 'unstable'])
    expect(plugin).to receive(:rest).and_return(rest_object)
    expect(rest_object).to receive(:get_rest).with(
      'environments/debug/cookbooks'
    )
    plugin.cookbooks('debug')
  end

  it 'grabs version from environment' do
    chef_input = {
      "url"=>
      "https://private-chef.in.mycasebook.org/organizations/in_casebook/cookbooks/ant",
        "versions"=>
      [{"url"=>
        "https://private-chef.in.mycasebook.org/organizations/in_casebook/cookbooks/ant/1.0.2",
          "version"=>"1.0.2"
      }]
    }
    expect(plugin.cookbook_version(chef_input)).to eq('1.0.2')
  end

  context '#versions' do
    it 'grabs right version' do
      src_cookbooks =
        {
        "ant"=>
        {
          "url"=> "https://private-chef.in.mycasebook.org/",
          "versions"=>
          [{"url"=>
            "https://private-chef.in.mycasebook.org/organizations/in_casebook/cookbooks/ant/1.0.2",
              "version"=>"1.0.2"
          }]
        },
        "apache2"=>
        {"url"=>
         "https://private-chef.in.mycasebook.org/organizations/in_casebook/cookbooks/apache2",
           "versions"=>
         [{"url"=>
           "https://private-chef.in.mycasebook.org/organizations/in_casebook/cookbooks/apache2/1.8.4",
             "version"=>"1.8.4"
         }]
        }
      }
        dst_cookbooks =
          {
          "ant"=>
          {
            "url"=>
            "https://private-chef.in.mycasebook.org/organizations/in_casebook/cookbooks/ant",
              "versions"=>
            [{"url"=>
              "https://private-chef.in.mycasebook.org/organizations/in_casebook/cookbooks/ant/1.0.2",
                "version"=>"1.0.1"
            }]
          },
          "apache2"=>
          {"url"=>
           "https://private-chef.in.mycasebook.org/organizations/in_casebook/cookbooks/apache2",
             "versions"=>
           [{"url"=>
             "https://private-chef.in.mycasebook.org/organizations/in_casebook/cookbooks/apache2/1.8.4",
               "version"=>"1.8.3"
           }]
          }
        }
          expect(plugin.versions(src_cookbooks, dst_cookbooks)).to match_array(
            [
              { name: 'ant', src_version: '1.0.2', dst_version: '1.0.1' },
              { name: 'apache2', src_version: '1.8.4', dst_version: '1.8.3' }
            ]
          )
    end

    it 'does not return version if the versions are same' do
      src_cookbooks =
        {
        "ant"=>
        {
          "url"=> "https://private-chef.in.mycasebook.org/",
          "versions"=>
          [{"url"=>
            "https://private-chef.in.mycasebook.org/organizations/in_casebook/cookbooks/ant/1.0.2",
              "version"=>"1.0.2"
          }]
        },
        "apache2"=>
        {"url"=>
         "https://private-chef.in.mycasebook.org/organizations/in_casebook/cookbooks/apache2",
           "versions"=>
         [{"url"=>
           "https://private-chef.in.mycasebook.org/organizations/in_casebook/cookbooks/apache2/1.8.4",
             "version"=>"1.8.4"
         }]
        }
      }
        dst_cookbooks =
          {
          "ant"=>
          {
            "url"=> "https://private-chef.in.mycasebook.org/",
            "versions"=>
            [{"url"=>
              "https://private-chef.in.mycasebook.org/organizations/in_casebook/cookbooks/ant/1.0.2",
                "version"=>"1.0.2"
            }]
          },
          "apache2"=>
          {"url"=>
           "https://private-chef.in.mycasebook.org/organizations/in_casebook/cookbooks/apache2",
             "versions"=>
           [{"url"=>
             "https://private-chef.in.mycasebook.org/organizations/in_casebook/cookbooks/apache2/1.8.4",
               "version"=>"1.8.4"
           }]
          }
        }
          expect(plugin.versions(src_cookbooks, dst_cookbooks)).to match_array([])
    end
  end

  it 'sets up knife subcommand' do
    ui_object = double(:ui)
    allow(plugin).to receive(:name_args).and_return(['debug', 'unstable'])
    expect(plugin).to receive(:validate)
    expect(plugin).to receive(:cookbooks).with('debug')
    expect(plugin).to receive(:cookbooks).with('unstable')
    expect(plugin).to receive(:versions)
    expect(plugin).to receive(:ui).and_return(ui_object).twice
    expect(ui_object).to receive(:msg).twice
    plugin.run
  end
end
