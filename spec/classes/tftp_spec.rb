# frozen_string_literal: true

require 'spec_helper'

describe 'pxe::tftp' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      it { is_expected.to compile }

      if os_facts[:os]['family'] == 'RedHat'
        it {
          is_expected.to contain_file('/etc/xinetd.d/tftp')
            .with_content(%r{^\s+disable\s+=\s+no$})
        }

        it {
          is_expected.to contain_file('/etc/xinetd.d/tftp')
            .with_content(%r{^\s+server_args\s+=\s+-s /var/lib/tftpboot$})
        }

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

          it {
            is_expected.to contain_file('/etc/xinetd.d/tftp')
              .with_content(%r{^\s+server_args\s+=\s+-s /var/lib/tftpboot --verbose$})
          }
        end
      elsif os_facts[:os]['family'] == 'Debian'
        it {
          is_expected.to contain_file('/etc/default/tftpd-hpa')
            .with_content(%r{^TFTP_USERNAME="tftp"$})
        }

        it {
          is_expected.to contain_file('/etc/default/tftpd-hpa')
            .with_content(%r{^TFTP_DIRECTORY="/srv/tftp"$})
        }

        it {
          is_expected.to contain_file('/etc/default/tftpd-hpa')
            .with_content(%r{^TFTP_ADDRESS="0.0.0.0:69"$})
        }

        it {
          is_expected.to contain_file('/etc/default/tftpd-hpa')
            .with_content(%r{^TFTP_OPTIONS="--secure"$})
        }
      end
    end
  end
end
