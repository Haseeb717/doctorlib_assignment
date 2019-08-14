class Event < ApplicationRecord
  SLOT_DURATION = 30.minutes
  AVAILABILITY_DAYS = 7

  KINDS = [
    OPENING_KIND = 'opening'.freeze,
    APPOINTMENT_KIND = 'appointment'.freeze
  ].freeze

  validates :kind, inclusion: { in: KINDS }
  validates :starts_at, presence: true
  validates :ends_at, presence: true

  validate :opening_uniques

  def self.availabilities(date)
    availabilities = []

    AVAILABILITY_DAYS.times.map do |index|
      availabilities << {
        date: date.to_date,
        slots: Event.availabilities_by_day(date)
      }
      date += index
    end

    return availabilities
  end

  private

  def self.availabilities_by_day(date)
    availabilities = []
    opening_slots = []
    appointment_slots = []

    Event.get_reccuring_openings(date, opening_slots)
    Event.get_non_reccuring_openings(date, opening_slots)

    opening_slots = opening_slots.sort.map { |slot| Event.format_slot(slot) }

    Event.get_appointments(date, appointment_slots)

    opening_slots.each do |opening|
      if not appointment_slots.include?(opening)
        availabilities << opening
      end
    end

    return availabilities
  end

  def self.get_reccuring_openings(date, opening_slots)
    openings = Event.where(kind: OPENING_KIND, weekly_recurring: true)
    openings.each do |opening|
      op_start = opening.starts_at.to_datetime
      op_end = opening.ends_at.to_datetime

      # If opening is set after tested date
      if date >= op_start.beginning_of_day
        days_difference = date.beginning_of_day - op_start.beginning_of_day
        if days_difference % 7 == 0
          # Do not format to allow sorting
          Event.add_event_to_slots(op_start, op_end, opening_slots, false)
        end
      end
    end

    return opening_slots
  end

  def self.get_non_reccuring_openings(date, opening_slots)
    openings = Event.where(kind: OPENING_KIND, weekly_recurring: false, starts_at: date.beginning_of_day..date.end_of_day)
    openings.each do |opening|
      op_start = opening.starts_at.to_datetime
      op_end = opening.ends_at.to_datetime

      # Do not format to allow sorting
      Event.add_event_to_slots(op_start, op_end, opening_slots, false)
    end

    return opening_slots
  end

  def self.get_appointments(date, appointment_slots)
    appointments = Event.where(kind: APPOINTMENT_KIND, starts_at: date.beginning_of_day..date.end_of_day)
    appointments.each do |appointment|
      at_start = appointment.starts_at.to_datetime
      at_end = appointment.ends_at.to_datetime

      Event.add_event_to_slots(at_start, at_end, appointment_slots, true)
    end

    return appointment_slots
  end

  def self.add_event_to_slots(event_starts_at, event_ends_at, slots, format)
    while event_starts_at < event_ends_at do
      if not slots.include? Event.format_slot(event_starts_at)
        if format == true
          slots << Event.format_slot(event_starts_at)
        else
          slots << event_starts_at
        end
      end
      event_starts_at += SLOT_DURATION
    end

    return slots
  end

  def opening_uniques
    return unless opening? && starts_at.present? && ends_at.present? && opening_exists?
    errors[:base] << "opening is already exist"
  end

  def opening_exists?
    self.class.openings.exists?(starts_at: starts_at, ends_at: ends_at)
  end

  def self.format_slot(slot)
    return slot.strftime("%-k:%M")
  end
end
