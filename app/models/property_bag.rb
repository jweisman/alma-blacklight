class PropertyBag < ActiveRecord::Base

	self.pluralize_table_names = false

	def self.get(name)
		where(name: name).first.value rescue nil
	end

	def self.set(name, val)
		where(name: name).first_or_initialize.tap do |prop|
      prop.name = name
      prop.value = val
      prop.save!
    end  
	end

end
