class AddAddressToActivities < ActiveRecord::Migration[5.1]
  def change
    add_column :activities, :address, :string
  end
end
