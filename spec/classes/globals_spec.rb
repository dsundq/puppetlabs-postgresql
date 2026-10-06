# frozen_string_literal: true

require 'spec_helper'

describe 'postgresql::globals' do
  context 'on a debian 11' do
    include_examples 'Debian 11'

    describe 'with no parameters' do
      it 'executes successfully' do
        expect(subject).to contain_class('postgresql::globals')
      end
    end

    describe 'manage_package_repo => true' do
      let(:params) do
        {
          manage_package_repo: true
        }
      end

      it 'pulls in class postgresql::repo' do
        expect(subject).to contain_class('postgresql::repo')
      end
    end
  end

  context 'on redhat 7' do
    include_examples 'RedHat 7'

    describe 'with no parameters' do
      it 'executes successfully' do
        expect(subject).to contain_class('postgresql::globals')
      end
    end

    describe 'manage_package_repo on RHEL => true' do
      let(:params) do
        {
          manage_package_repo: true,
          repo_proxy: 'http://proxy-server:8080'
        }
      end

      it 'pulls in class postgresql::repo' do
        expect(subject).to contain_class('postgresql::repo')
      end

      it do
        expect(subject).to contain_yumrepo('yum.postgresql.org').with(
          'enabled' => '1',
          'proxy' => 'http://proxy-server:8080',
        )
        expect(subject).to contain_yumrepo('pgdg-common').with(
          'enabled' => '1',
          'proxy' => 'http://proxy-server:8080',
        )
      end
    end

    describe 'repo_baseurl on RHEL => mirror.localrepo.com' do
      let(:params) do
        {
          manage_package_repo: true,
          repo_baseurl: 'http://mirror.localrepo.com/pgdg-postgresql',
          yum_repo_commonurl: 'http://mirror.localrepo.com/pgdg-common'
        }
      end

      it 'pulls in class postgresql::repo' do
        expect(subject).to contain_class('postgresql::repo')
      end

      it do
        expect(subject).to contain_yumrepo('yum.postgresql.org').with(
          'enabled' => '1',
          'baseurl' => 'http://mirror.localrepo.com/pgdg-postgresql',
        )
        expect(subject).to contain_yumrepo('pgdg-common').with(
          'enabled' => '1',
          'baseurl' => 'http://mirror.localrepo.com/pgdg-common',
        )
      end
    end
  end

  # Guards the RedHat-family $default_version selector in globals.pp. Each
  # EL major must auto-resolve to the expected PostgreSQL version; without a
  # matching entry globals.pp raises
  # fail('No preferred version defined or automatically detected.') and the
  # catalog does not compile. $globals_version is a local var, not a class
  # param, so it is asserted indirectly via the version-derived PGDG GPG key
  # file that the repo setup lays down (package_version strips the dot:
  # '10' => '10', '13' => '13', '16' => '16').
  {
    'RedHat 8' => '10',
    'RedHat 9' => '13',
    'RedHat 10' => '16'
  }.each do |ctx, pg_version|
    context "on #{ctx.downcase}" do
      include_examples ctx

      describe 'with no parameters' do
        it 'compiles, proving a default version resolves' do
          expect(subject).to contain_class('postgresql::globals')
        end
      end

      describe 'manage_package_repo => true' do
        let(:params) do
          {
            manage_package_repo: true
          }
        end

        it "resolves the default to PostgreSQL #{pg_version}" do
          expect(subject).to contain_file("/etc/pki/rpm-gpg/RPM-GPG-KEY-PGDG-#{pg_version}")
        end
      end
    end
  end
end
