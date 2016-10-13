module Representable
  class Populator
    FindOrInstantiate = ->(input, options) {
      binding = options[:binding]

      object_class = binding[:class].(input, options)
      object       = object_class.find_by(id: input["id"]) || object_class.new
      object
     }

    # pipeline: [StopOnExcluded, AssignName, ReadFragment, StopOnNotFound, OverwriteOnNil, AssignFragment, #<Representable::Function::CreateObject:0x9805a44>, #<Representable::Function::Decorate:0x9805a1c>, Deserialize, Set]

    def self.apply!(options)
      return unless populator = options[:populator]

      options[:parse_pipeline] = ->(input, options) do
        pipeline = Pipeline[*parse_functions] # TODO: AssignFragment
        pipeline = Pipeline::Insert.(pipeline, populator, replace: CreateObject::Populator) # let the actual populator do the job.
        # puts pipeline.extend(Representable::Pipeline::Debug).inspect
        pipeline
      end
    end
  end

  FindOrInstantiate = Populator::FindOrInstantiate
end
