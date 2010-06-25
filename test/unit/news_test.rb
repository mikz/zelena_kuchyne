require File.dirname(__FILE__) + '/../test_helper'

class NewsTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  def test_valid_news
    assert_equal(3, News.valid_news(:limit => 3).length)
    News.valid_news.each do |news|
      assert news.publish_at.to_date <= Date.today
      assert news.expire_at.nil? || (news.expire_at >= Date.today)
    end
  end
  
  def test_negative_duration
    news = News.new(:title => "Zkřížená novinka", :body => "Křííž, křííž, křííž", :publish_at => '2008-12-01', :expire_at => '2008-11-01')
    assert !news.valid?
  end
end