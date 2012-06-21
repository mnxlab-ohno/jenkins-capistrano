
module Capistrano
  module Deploy
    module SCM

      class Jenkins < Base

        autoload :Client, 'jenkins-capistrano/client'

        def head
          last_successful_build_number
        end

        def query_revision(revision)
          raise "Invalid build number: #{revision}" unless revision =~ /^\d+$/
          raise "No such build number: #{revision}" unless revision_exists? revision
          # TODO stable check
          revision
        end

        def checkout(revision, destination)
          # there is possibility of the directory name collision,
          # but since mktemp command is not portable, use Dir.tmpdir instead
          tmpdir = Dir.tmpdir
          execute = []
          execute << "cd #{tmpdir}"
          execute << "curl -sO #{artifact_root_url(revision)}"
          execute << "unzip #{artifact_zip_url(revision)} -P #{destination}"
          execute << "rm -rf #{destination}"

          execute.compact.join(" && ").gsub(/\s+/, ' ')
        end

        alias_method :export, :checkout

        def log(from, to=nil)
          logger.info 'Jenkins does not support log'
          'true'
        end

        def diff(from, to=nil)
          logger.info 'Jenkins does not support diff'
          'true'
        end

        private
        def client
          @client ||= @client = Client.new(jenkins_host, {:username => jenkins_username, :password => jenkins_password})
        end

        def last_successful_build_number
          lsb = job_summary["lastSuccessfulBuild"]
          raise "No last successful build found for '#{job_name}'" unless lsb
          lsb["number"]
        end

        def revision_exists?(revision)
          job_summary["builds"].find {|b| b["number"] == revision }
        end

        def artifact_zip_url(revision)
          "#{repository}/#{revision}/artifact/*zip*/archive.zip"
        end

        def job_summary
          @job_summary ||= client.job_summary(job_name)
        end

        def jenkins_host
          @jenkins_host ||= URI.parse(variable(:repository)).host || variable(:jenkins_host)
        end

        def jenkins_username
          @jenkins_username ||= variable(:scm_username) || variable(:jenkins_username)
        end

        def jenkins_password
          @jenkins_password ||= variable(:scm_password) ||variable(:jenkins_password)
        end

        def job_name
          @job_name ||= URI.parse(variable(:repository)).path.split('/').last
        end

      end
    end
  end
end

