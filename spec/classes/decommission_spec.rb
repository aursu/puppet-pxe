# frozen_string_literal: true

require 'spec_helper'

describe 'pxe::decommission' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      debian = (os_facts[:os]['family'] == 'Debian')
      tftp_package = debian ? 'tftpd-hpa' : 'tftp-server'
      ipxe_package = debian ? 'ipxe' : 'ipxe-bootimgs'
      dhcp_package = debian ? 'isc-dhcp-server' : 'dhcp-server'
      web_package  = debian ? 'apache2' : 'httpd'
      tftp_root    = debian ? '/srv/tftp' : '/var/lib/tftpboot'

      context 'with default parameters' do
        it { is_expected.to compile.with_all_deps }

        it { is_expected.to contain_package(tftp_package).with_ensure('purged') }
        it { is_expected.to contain_package(ipxe_package).with_ensure('purged') }
        it { is_expected.to contain_package(dhcp_package).with_ensure('purged') }
        it { is_expected.to contain_package(web_package).with_ensure('purged') }

        # nmap is a general-purpose tool and must survive unless asked for.
        it { is_expected.not_to contain_package('nmap') }

        # No Service resources: a unit that no longer exists would fail forever.
        it { is_expected.not_to contain_service('tftpd-hpa') }
        it { is_expected.not_to contain_service(dhcp_package) }

        # ⚠ The inverse of pxe::ubuntu's `mount { ensure => mounted }` must be a
        # mount resource, not a umount: `ensure => absent` removes the fstab
        # entry too. Leaving the entry behind pointing at a deleted ISO makes
        # the host fail local-fs.target and drop to emergency mode on its next
        # reboot -- which is how a decommissioned host was lost.
        it {
          is_expected.to contain_mount('/mnt/iso/ubuntu/24.04.3').with_ensure('absent')
        }
        it {
          is_expected.to contain_mount('/mnt/iso/ubuntu/22.04.5').with_ensure('absent')
        }
        it { is_expected.not_to contain_exec('pxe::decommission unmount ISOs') }
        it { is_expected.to contain_exec('pxe::decommission remove /diskless') }
        it { is_expected.to contain_exec('pxe::decommission remove /mnt/iso') }
        it { is_expected.to contain_exec("pxe::decommission remove #{tftp_root}") }

        # The ISO files these mounts read from live inside the tree the removal
        # execs delete, so the ordering is load-bearing, not cosmetic.
        it 'retires the mounts before deleting anything' do
          expect(catalogue).to contain_exec('pxe::decommission remove /diskless')
            .that_requires('Mount[/mnt/iso/ubuntu/24.04.3]')
        end

        it 'purges packages before retiring the mounts' do
          expect(catalogue).to contain_mount('/mnt/iso/ubuntu/24.04.3')
            .that_requires("Package[#{tftp_package}]")
        end

        it 'guards each removal on the directory existing' do
          expect(catalogue).to contain_exec('pxe::decommission remove /diskless')
            .with_onlyif('test -d /diskless')
        end
      end

      context 'with remove_nmap => true' do
        let(:params) { { remove_nmap: true } }

        it { is_expected.to contain_package('nmap').with_ensure('purged') }
      end

      context 'with remove_web => false' do
        let(:params) { { remove_web: false } }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.not_to contain_package(web_package) }
        it { is_expected.to contain_package(tftp_package).with_ensure('purged') }
      end

      context 'with remove_storage => false' do
        let(:params) { { remove_storage: false } }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_package(tftp_package).with_ensure('purged') }
        it { is_expected.not_to contain_exec('pxe::decommission remove /diskless') }
        it { is_expected.not_to contain_mount('/mnt/iso/ubuntu/24.04.3') }
      end

      # ⚠ The default only covers the releases the module currently tracks. A
      # host that mounted one the module has moved past keeps an fstab entry
      # nothing names -- the exact state that cost a host. Enumerate from the
      # host's own fstab instead of trusting the default.
      context 'with a stale release the module no longer tracks' do
        let(:params) do
          { 'iso_mounts' => ['/mnt/iso/ubuntu/24.04.2', '/mnt/iso/ubuntu/24.04.3'] }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_mount('/mnt/iso/ubuntu/24.04.2').with_ensure('absent') }
        it { is_expected.to contain_mount('/mnt/iso/ubuntu/24.04.3').with_ensure('absent') }
        it { is_expected.not_to contain_mount('/mnt/iso/ubuntu/22.04.5') }
      end

      context 'on a host that never mounted an ISO' do
        let(:params) { { 'iso_mounts' => [] } }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.not_to contain_mount('/mnt/iso/ubuntu/24.04.3') }
        it { is_expected.to contain_exec('pxe::decommission remove /diskless') }
      end

      context 'with an explicit package list' do
        let(:params) { { packages: ['tftpd-hpa', 'somethingelse'] } }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_package('somethingelse').with_ensure('purged') }
        it { is_expected.not_to contain_package(dhcp_package) }
      end
    end
  end
end
