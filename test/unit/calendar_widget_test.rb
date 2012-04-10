# -*- encoding : utf-8 -*-
require File.dirname(__FILE__) + '/../test_helper'

class CalendarWidgetTest < ActiveSupport::TestCase

  def test_date_parsing
    assert_equal ['2000-01-01', '2002-01-01'], CalendarWidget.parse('2000-01-01;2002-01-01')
    assert_equal ['2000-01-01', '2002-01-01'], CalendarWidget.parse('2002-01-01;2000-01-01')
    assert_equal ['2000-01-01', '2000-01-01'], CalendarWidget.parse('2000-01-01')
    assert_equal [Date.today, Date.today], CalendarWidget.parse(nil)
    assert_equal [Date.today, Date.today], CalendarWidget.parse("")
  end
end

