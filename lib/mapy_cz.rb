require "open-uri"

module MapyCz
  def find_address options={}
    data = get_json_data "http://www.mapy.cz/search?query=#{URI.encode("#{options[:street]} #{options[:house_no]}, #{options[:city]}")}"
    results = data[data["type"]]["result"] || []
    addresses = []
    results.each {|result|
      addresses.push object_info(result["ids"]) if result["type"] == "location"
    }
    return addresses
  end

  def object_info poi_id
    info = {}
    data = get_json_data "http://www.mapy.cz/basepoi/detail?output=json&requestType=xmlhttp&encoding=utf8&adr=#{poi_id}"
    tmp = []
    return unless data["status"].to_i == 200
    content = data["obsah"].first["cont"].gsub(/(<\/p><p[^>]*>)/m,"<br />").gsub(/(<\/p>)|(<p[^>]*>)/m,"").gsub(/&nbsp;/,"").split(/<br\s*\/>/m)
    title = data["obsah"].first["title"].split(",").first.strip
    if title =~ /^(ulice )/
      info[:street] = title.gsub(/^(ulice )/, "").strip
    else
      tmp = title.scan /(.+)(?: )(\S+)/
      info[:street] = tmp.first.first.strip
      info[:house_no] = tmp.first.last.strip
    end
    info[:country] = content.last.gsub(/(stát )/,"").strip
    case content.length
      when 5
        info[:city] = content[0].strip
      when 6
        info[:zip] = content[0].scan(/(\d+)(.*)/).first.first.strip
        info[:district] = content[1].gsub(/^(část obce )/,"").strip
        info[:city] = content[0].scan(/(\d+)(.*)/).first.last.strip
    end
    return info
  end

  def translit str
    ActiveSupport::Multibyte::Handlers::UTF8Handler.normalize(str.to_s,:d).split(//u).reject { |e| e.length > 1 }.join
  end

  private
  
  def get_json_data(url, ret = true)
    uri = URI.parse url
    data = ""
    uri.open do |f|
      data += f.read
    end
    data.gsub! /(\/\*)(\s|\S)+(\*\/)/, ""
    data.gsub! /(\r|\n|\t)/, ""
    data.gsub!("\\'","''")
    begin
      data = ActiveSupport::JSON.decode(data)
    rescue Exception => e
      if ret
        data = get_json_data url, false
      else
        raise e
      end
    end
    data
  end
end