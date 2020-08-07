require "http"
require "json"
require "./**"

  module CRYSTALLIX
    CONFIG = JSON.parse(File.read("cfg/config.json"))
    SITES = JSON.parse(File.read("cfg/sites.json"))

    def self.start

      begin
        server = self.generateServer
        puts "Binding address: #{CONFIG["address"].as_s}:#{CONFIG["port"].as_i}"
        server.bind_tcp(host: CONFIG["address"].as_s, port: CONFIG["port"].as_i)
        if CONFIG["ssl"]["use?"].as_bool
          ssl = OpenSSL::SSL::Context::Server.new
          ssl.certificate_chain = CONFIG["ssl"]["chain"].as_s
          ssl.private_key = CONFIG["ssl"]["key"].as_s
          server.bind_tls(host: CONFIG["address"].as_s, port: CONFIG["ssl"]["port"].as_i, context: ssl)
          puts "Binding address for SSL: #{CONFIG["address"].as_s}:#{CONFIG["ssl"]["port"].as_i}"
        end
        puts "Started!"
        server.listen
      rescue ex
        puts "Start error: \n\n#{ex}\n"
      end
    end

    def self.generateServer
      HTTP::Server.new do |context|
        context.response.headers["Content-Type"] = "text/html; charset=UTF-8"
        context.response.headers["Server"] = "Crystallix"
        context.response.headers["Date"] = Time.local.to_s

        request = context.request
        headers = request.headers
        resource = request.resource.includes?('?') ? request.resource.split('?')[0] : request.resource

        sitename = "@"

        if headers["Host"]?
          sitename = headers["Host"]
          sitename = sitename.split(':')[0] if sitename.includes?(':')
          sitename = "@" if !SITES[sitename]?
        end

        file = SITES[sitename]["path"].as_s + resource

        if Dir.exists?(file)
          indexes = SITES[sitename]["index"]? ? SITES[sitename]["index"] : SITES["@"]["index"]
          i = 0
          while i < indexes.size
            if File.exists?(file + indexes[i].as_s)
              file += indexes[i].as_s
              break
            end
            i += 1
          end
        end
        if File.exists?(file)
          ext = file.includes?(".") ? file.split(".").last : ""
          if CONFIG["addons"][ext]?
            cmd = {} of String => String
            cmd["SERVER_NAME"] = sitename
            cmd["REDIRECT_STATUS"] = "true"
            cmd["SCRIPT_FILENAME"] = "#{file}"
            cmd["SERVER_PROTOCOL"] = "#{request.version}"
            cmd["REQUEST_METHOD"] = "#{request.method}"
            cmd["QUERY_STRING"] = "#{request.query}"
            cmd["REMOTE_ADDR"] = "#{request.remote_address}"
            cmd["SERVER_PORT"] = "#{CONFIG["port"].as_i}"
            cmd["CONTENT_TYPE"] = headers["Content-Type"] if headers["Content-Type"]?
            cmd["HTTP_USER_AGENT"] = headers["User-Agent"] if headers["User-Agent"]?
            cmd["HTTP_ACCEPT"] = headers["Accept"] if headers["Accept"]?
            cmd["HTTP_COOKIE"] = headers["Cookie"] if headers["Cookie"]?
            if request.method == "POST"
              body = request.body.not_nil!.gets_to_end
              cmd["CONTENT_LENGTH"] = "#{headers["Content-Length"]? ? headers["Content-Length"] : body.size}"
              cmd["end"] = "echo '#{body}' | "
            end
            exec = ""
            cmd.each do |var, value|
              exec += "export #{var}='#{value}'\n"
            end
            exec += cmd["end"] if cmd["end"]?
            exec += ext == "crweb" ? "./#{file}" : CONFIG["addons"][ext].as_s

            response = `#{exec}`.gsub("\r\n", "\n")
            response.split("\n").each do |header|
              break if header.empty?
              header = header.split(": ")
              context.response.headers[header[0]] = header[1]
            end
            context.response.print(response.sub(response.split("\n\n")[0], ""))
          else
            context.response.print(File.read(file))
          end
        else
          context.response.status_code = 404
        end

        context.response.status_code = context.response.headers["Status"].split(" ")[0].to_i if context.response.headers["Status"]?

        if context.response.status_code != 200 && SITES[sitename]["errors"]? && SITES[sitename]["errors"]["#{context.response.status_code}"]?
          file = SITES[sitename]["errors"]["#{context.response.status_code}"].as_s.gsub("%site_path%", SITES[sitename]["path"].as_s)
          if SITES[sitename]["errors"]["redirect"]? && SITES[sitename]["errors"]["redirect"].as_bool && File.exists?(file)
            context.response.headers["Location"] = SITES[sitename]["errors"]["#{context.response.status_code}"].as_s.gsub("%site_path%", "")
          else
            context.response.print(File.exists?(file) ? File.read(file) : "#{context.response.status_code}")
          end
        end

        context.response.status_code = 308 if context.response.headers["Location"]?

        context.response.close
      end
    end
end

CRYSTALLIX.start
