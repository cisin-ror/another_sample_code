class Classification < ActiveRecord::Base
  include Algorithms
  acts_as_tree_with_dotted_ids :order => "name"

  before_validation :set_resource_for_child

  attr_accessible :name, :purchased_previously, :spend, :spend_previous,
  attr_accessor :is_cloned, :parent_name, :parent_path, :answer_ques_this_parent
  belongs_to :user
  belongs_to :resource
  has_many :algorithms

  scope :first_level, where(:parent_id => nil)
  scope :for_reports, where(:include_in_reports => true)

  accepts_nested_attributes_for :classification_experience
  accepts_nested_attributes_for :classification_supply

  accepts_nested_attributes_for :children
  def children_attributes_with_self_assignment=(attributes)
    self.children_attributes_without_self_assignment = attributes.map {|a| a.merge(:resource => self.resource)}
  end

  delegate :annual_spend, :currency, :company_spend, :to => :resource

  validates_presence_of :name, :form_filled_date
  validates_presence_of :annual_spend,
                        :aggrement_length, :if => :should_i_validate?

  validates_inclusion_of :purchased_previously, :in => [true, false], :if => :should_i_validate?

  before_update :nullify_dependent_fields

  def has_no_incumbent?
    classification_suppliers.blank?
  end

  def descendants_children(classified, current_user)
    all = []
    children.each do |classification|
      unless (classified.present? && classification == classified)
        descendants = classification.descendants_children(classified, current_user)
        can_update = current_user.can?(:update, classification)
        all << {
                  :name => classification.name,
                  :id => classification.id,
                  :children => descendants,
               }
      end
    end
    all
  end

  def placeholder?
    dont_check_those = placeholders
    check_those_attributes = self.attributes.clone.delete_if {|k, v| (dont_check_those).include?(k)}
    attrs_with_values = check_those_attributes.delete_if {|k, v| v.eql?(0) || v.eql?(nil)}

    !attrs_with_values.any?
  end

  def as_json(options)
    super({:methods => [:placeholder?]}.merge(options))
  end

  def can_add_more_suppliers?
    if classification_suppliers.last.errors.any?
      (classification_supply.number_of_suppliers.to_i > (classification_suppliers.count + 1)) ? true : false
    else
      (classification_supply.number_of_suppliers.to_i > (classification_suppliers.size)) ? true : false
    end
  end

  def spend_with_suppliers_sum
    classification_suppliers.map(&:spend_with).sum
  end

  def diff_btwn_spend_with_sum_and_annual_spend
    annual_spend - spend_with_suppliers_sum
  end

  def clone_classification_with_its_associations(current_user)
    new_classification = self.dup :include => [:classification_supply,
                                               :classification_suppliers], :validate => false

    new_classification.user = current_user
    new_classification.is_cloned = true
    new_classification.name = I18n.t(:clone_of) + self.name

    new_classification.save(:validate => false)
    if new_classification.dotted_ids.present?
      dotted_ids = new_classification.dotted_ids.split('.')
      if dotted_ids.last == self.id.to_s
        dotted_ids.pop

        dotted_ids.push(new_classification.id.to_s)
        dotted_ids = dotted_ids.map { |i| i.to_s }.join(".")
        new_classification.update_column(:dotted_ids,dotted_ids)
      end
    end
    new_classification
  end

  def switching_currency
    is_switching_costs ? cost_of_switching.to_f : 0
  end

  def cost_switching
    (switching_currency/annual_spend)*100 if annual_spend.present?
  end

private

  def should_i_validate?
    !placeholder?
  end
end
