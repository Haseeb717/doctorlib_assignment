require 'test_helper'

class EventTest < ActiveSupport::TestCase

	test "one simple test example" do
    
    Event.create kind: 'opening', starts_at: DateTime.parse("2014-08-04 09:30"), ends_at: DateTime.parse("2014-08-04 12:30"), weekly_recurring: true
    Event.create kind: 'appointment', starts_at: DateTime.parse("2014-08-11 10:30"), ends_at: DateTime.parse("2014-08-11 11:30")

    availabilities = Event.availabilities DateTime.parse("2014-08-10")
    assert_equal Date.new(2014, 8, 10), availabilities[0][:date]
    assert_equal [], availabilities[0][:slots]
    assert_equal Date.new(2014, 8, 11), availabilities[1][:date]
    assert_equal ["9:30", "10:00", "11:30", "12:00"], availabilities[1][:slots]
    assert_equal [], availabilities[2][:slots]
    assert_equal Date.new(2014, 8, 16), availabilities[6][:date]
    assert_equal 7, availabilities.length
  end
	
  test 'invalid with blank kind' do
    event = Event.new(valid_event_attributes(kind: nil))

    refute event.valid?, 'event is valid with blank kind'
    assert_not_nil event.errors[:kind], 'must be present'
  end

  test 'invalid with invalid kind' do
    event = Event.new(valid_event_attributes(kind: 'test'))

    refute event.valid?, 'event is valid with invalid kind'
    assert_not_nil event.errors[:kind], 'must be valid'
  end

  test 'invalid with blank starts_at' do
    event = Event.new(valid_event_attributes(starts_at: nil))

    refute event.valid?, 'event is valid with blank starts_at'
    assert_not_nil event.errors[:starts_at], 'must be present'
  end

  test 'invalid with blank ends_at' do
    event = Event.new(valid_event_attributes(ends_at: nil))

    refute event.valid?, 'event is valid with blank ends_at'
    assert_not_nil event.errors[:ends_at], 'must be present'
  end

  test 'invalid when opening already exists' do
    Event.create!(valid_event_attributes)
    event = Event.new(valid_event_attributes)

    refute event.valid?, 'event is valid when the same opening event already exists'
    assert_not_nil event.errors[:base], 'opening is already exist'
  end

  test "appointment out of opening test" do

    Event.create kind: 'opening', starts_at: DateTime.parse("2014-08-04 09:30"), ends_at: DateTime.parse("2014-08-04 12:30"), weekly_recurring: true
    Event.create kind: 'appointment', starts_at: DateTime.parse("2014-08-11 09:00"), ends_at: DateTime.parse("2014-08-11 13:00")

    availabilities = Event.availabilities DateTime.parse("2014-08-10")
    assert_equal Date.new(2014, 8, 11), availabilities[1][:date]
    assert_equal [], availabilities[1][:slots]
  end

  test "no opening test" do

    availabilities = Event.availabilities DateTime.parse("2014-08-10")
    assert_equal 7, availabilities.length
  end

  test '.availabilities' do
    create_opening('2014-08-03 09:30', '2014-08-03 10:30', recurred: true)
    create_opening('2014-08-10 13:30', '2014-08-10 14:30')
    create_opening('2014-08-04 09:30', '2014-08-04 12:30', recurred: true)
    create_opening('2014-08-05 09:30', '2014-08-05 12:30', recurred: true)
    create_opening('2014-08-06 09:30', '2014-08-06 12:30', recurred: true)
    create_opening('2014-08-13 13:30', '2014-08-13 14:30')
    create_opening('2014-08-07 09:30', '2014-08-07 12:30', recurred: true)
    create_opening('2014-08-08 09:30', '2014-08-08 12:30', recurred: true)
    create_opening('2014-08-09 09:30', '2014-08-09 12:30', recurred: true)
    create_opening('2014-08-16 13:30', '2014-08-16 14:30')

    create_opening('2014-08-17 15:00', '2014-08-17 17:00', recurred: true)
    create_opening('2014-08-18 15:00', '2014-08-18 17:00', recurred: true)
    create_opening('2014-08-19 15:00', '2014-08-19 17:00', recurred: true)
    create_opening('2014-08-20 15:00', '2014-08-20 17:00', recurred: true)
    create_opening('2014-08-21 15:00', '2014-08-21 17:00', recurred: true)
    create_opening('2014-08-22 15:00', '2014-08-22 17:00', recurred: true)
    create_opening('2014-08-23 15:00', '2014-08-23 17:00', recurred: true)


    create_appointment('2014-08-10 09:30', '2014-08-10 10:30')
    create_appointment('2014-08-10 14:00', '2014-08-10 14:30')

    create_appointment('2014-08-11 09:30', '2014-08-11 12:00')
    create_appointment('2014-08-12 09:30', '2014-08-12 12:00')

    create_appointment('2014-08-13 11:30', '2014-08-13 12:30')
    create_appointment('2014-08-13 13:30', '2014-08-13 14:30')

    create_appointment('2014-08-14 09:30', '2014-08-14 12:00')
    create_appointment('2014-08-15 13:30', '2014-08-15 14:00')

    create_appointment('2014-08-16 09:30', '2014-08-16 12:30')
    create_appointment('2014-08-16 09:30', '2014-08-16 12:30')

    expected_availabilities = [
      { date: Date.new(2014, 8, 10), slots: %w[13:30] },
      { date: Date.new(2014, 8, 11), slots: %w[12:00] },
      { date: Date.new(2014, 8, 12), slots: %w[12:00] },
      { date: Date.new(2014, 8, 13), slots: %w[9:30 10:00 10:30 11:00] },
      { date: Date.new(2014, 8, 14), slots: %w[12:00] },
      { date: Date.new(2014, 8, 15), slots: %w[9:30 10:00 10:30 11:00 11:30 12:00] },
      { date: Date.new(2014, 8, 16), slots: %w[13:30 14:00] },
    ]

    assert_equal expected_availabilities, Event.availabilities(DateTime.parse('2014-08-10'))
  end

  test '.available_slots' do
    create_opening('2014-08-03 09:30', '2014-08-03 10:30', recurred: true)
    create_opening('2014-08-10 13:30', '2014-08-10 14:30')

    create_appointment('2014-08-10 09:30', '2014-08-10 10:30')
    create_appointment('2014-08-10 14:00', '2014-08-10 14:30')

    expected_slots = %w[13:30]

    assert_equal expected_slots, Event.available_slots(DateTime.parse('2014-08-10'))
  end

  private

  def valid_event_attributes(
    kind: 'opening',
    starts_at: DateTime.parse('2014-08-04 09:30'),
    ends_at: DateTime.parse('2014-08-04 10:30')
  )
    { kind: kind, starts_at: starts_at, ends_at: ends_at }
  end

  def create_opening(starts_at_string, ends_at_string, recurred: false)
    Event.create(
      kind: 'opening',
      starts_at: DateTime.parse(starts_at_string),
      ends_at: DateTime.parse(ends_at_string),
      weekly_recurring: recurred
    )
  end

  def create_appointment(starts_at_string, ends_at_string)
    Event.create(
      kind: 'appointment',
      starts_at: DateTime.parse(starts_at_string),
      ends_at: DateTime.parse(ends_at_string)
    )
  end
end
