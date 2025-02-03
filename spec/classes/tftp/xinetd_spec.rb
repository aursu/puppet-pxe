# frozen_string_literal: true

require 'spec_helper'

describe 'pxe::tftp::xinetd' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile.with_all_deps }

      it {
        is_expected.to contain_file('/etc/xinetd.d/tftp')
          .with_content(%r{^\s+disable\s+=\s+no$})
      }

      if os_facts[:os]['family'] == 'RedHat'
        it {
          is_expected.to contain_file('/etc/xinetd.d/tftp')
            .with_content(%r{^\s+server_args\s+=\s+-s /var/lib/tftpboot$})
        }
      elsif os_facts[:os]['family'] == 'Debian'
        it {
          is_expected.to contain_file('/etc/xinetd.d/tftp')
            .with_content(%r{^\s+server_args\s+=\s+-s /srv/tftp$})
        }
      end

      context 'when tftp server disabled' do
        let(:params) do
          {
            service_enable: false,
          }
        end

        it {
          is_expected.to contain_file('/etc/xinetd.d/tftp')
            .with_content(%r{^\s+disable\s+=\s+yes$})
        }
      end

      context 'when tftp server disabled' do
        let(:params) do
          {
            verbose: true,
          }
        end

        if os_facts[:os]['family'] == 'RedHat'
          it {
            is_expected.to contain_file('/etc/xinetd.d/tftp')
              .with_content(%r{^\s+server_args\s+=\s+-s /var/lib/tftpboot --verbose$})
          }
        elsif os_facts[:os]['family'] == 'Debian'
          it {
            is_expected.to contain_file('/etc/xinetd.d/tftp')
              .with_content(%r{^\s+server_args\s+=\s+-s /srv/tftp --verbose$})
          }
        end
      end
    end
  end
end
