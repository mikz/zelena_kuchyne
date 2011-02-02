class ImagesController < ApplicationController
  skip_before_filter :verify_authenticity_token
  def create
    #TODO: add a security check
    user = User.find get_session_data(params[:_zelena_kuchyne_session])[:user]
    file = params["Filedata"]
  
    tmp_path = "#{RAILS_ROOT}/tmp/upload/#{user.id}"
    fpath = "#{tmp_path}/#{file.original_filename}"
    Dir.mkdir(tmp_path) unless File.exists? tmp_path
    File.open(fpath, 'wb') do |f| #TODO: check if a previous file exists with the same name
      f.write file.read
    end
    render :nothing => true
  end
  
  def image_upload
    user = UserSystem.current_user
    response = {}
    if user.belongs_to? :admins
      file = params["NewFile"]
      if file
        begin
          url = "/pictures/user_uploads/#{user.id}/"
          tmp_path = "#{RAILS_ROOT}/public#{url}"
          fpath = "#{tmp_path}/#{file.original_filename}"
          Dir.mkdir(tmp_path) unless File.exists? tmp_path
          File.open(fpath, 'wb') do |f| #TODO: check if a previous file exists with the same name
            f.write file.read
          end
          response[:errno] = 0
          response[:url] = url + file.original_filename
        rescue Exception => e
          response[:errno] = 1
          response[:errmsg] = e.inspect
        end
      else
        response[:errno] = 1
        response[:errmsg] = t(:e_missing_file)
      end
    else
      response[:errno] = 1
      response[:errmsg] = t(:e_not_authorized)
    end
    render :text => %{
    <script type="text/javascript">
      window.parent.OnUploadCompleted( #{response[:errno]}, #{response[:url].to_s.inspect}, '', #{response[:errmsg].to_s.inspect} );
    </script>
    }
  end
    

  protected
  
  def get_session_data(session_string)
    secret = session.instance_values['dbman'].instance_values['secret']
    session_data, session_digest = session_string.split('--')
    
    control_hash = OpenSSL::HMAC.hexdigest(OpenSSL::Digest::Digest.new('SHA1'), secret, session_data)
    raise AccessDenied unless (control_hash == session_digest)
    sess = Base64::decode64(session_data)
    sess = Marshal.load(sess)
    return sess
  end
end
