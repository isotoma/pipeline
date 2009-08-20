module Pipeline
  class Base < ActiveRecord::Base
    set_table_name :pipeline_instances
    
    # :not_started ---> :in_progress ---> :completed
    #                       ^ |       \-> :failed
    #                       | v
    #                     :paused
    symbol_attr :status
    transactional_attr :status
    private :status=

    has_many :stages, :class_name => 'Pipeline::Stage::Base', :foreign_key => 'pipeline_instance_id', :dependent => :destroy

    class_inheritable_accessor :defined_stages, :instance_writer => false
    self.defined_stages = []

    class_inheritable_accessor :failure_mode, :instance_writer => false
    self.failure_mode = :pause
    
    def self.define_stages(stages)
      self.defined_stages = stages.build_chain
    end

    def self.default_failure_mode=(mode)
      new_mode = [:pause, :cancel].include?(mode) ? mode : :pause
      self.failure_mode = new_mode
    end

    def after_initialize
      if new_record?
        self[:status] = :not_started
        self.class.defined_stages.each do |stage_class|
          stages << stage_class.new(:pipeline => self)
        end
      end
    end
    
    def perform
      reload unless new_record?
      raise InvalidStatusError.new(status) unless ok_to_resume?
      begin
        _setup
        stages.each do |stage|
          stage.perform unless stage.completed?
        end
        self.status = :completed
      rescue IrrecoverableError
        self.status = :failed
      rescue RecoverableError => e
        if e.input_required?
          self.status = :paused
        else
          raise e
        end
      rescue Exception
        self.status = (failure_mode == :cancel ? :failed : :paused)
      end
    end
    
    def cancel
      raise InvalidStatusError.new(status) unless ok_to_resume?
      self.status = :failed
    end
    
    def ok_to_resume?
      [:not_started, :paused].include?(status)
    end

    private
    def _setup
      self.attempts += 1
      self.status = :in_progress
    end
  end
end