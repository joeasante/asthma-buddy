module MedicationsHelper
  # Returns the correct partial path for a medication based on whether it is a course.
  def medication_partial(medication)
    medication.course? ? "settings/medications/course_medication" : "settings/medications/medication"
  end
end
