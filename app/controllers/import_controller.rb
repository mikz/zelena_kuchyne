class ImportController < ApplicationController
  before_filter { |c| c.must_belong_to_one_of(:admins)}
  def import
    importer = ("Importers::#{params[:file_format].camelize}").constantize.new(params[:file])
    render :text => importer.import
  end
end
