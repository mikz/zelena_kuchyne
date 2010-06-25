module ExposureHelper
  def validation_error_for record
    "<div id='validation_error_#{record.new_record? ?  'new' : record.id}' style='display: none;'/>"
  end
  
  def radio_buttons(f, row_id, name, fields)
    html = ""
    for field in fields
      html += %{<p><label for="#{row_id}_#{field[:name]}">#{locales[field[:name]]}</label><br />
        #{f.radio_button name, field[:value], :id=> "#{row_id}_#{field[:name]}" }#{locales[field[:note]] if field[:note]}</p>
      }
    end
    html
  end
end