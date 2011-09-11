module Pod
  class Specification
    class Set
      def self.sets
        @sets ||= {}
      end

      def self.by_specification_name(name)
        sets[name]
      end

      # This keeps an identity map of sets so that you always get the same Set
      # instance for the same pod directory.
      def self.by_pod_dir(pod_dir)
        set = new(pod_dir)
        sets[set.name] ||= set
        sets[set.name]
      end

      def initialize(pod_dir)
        @pod_dir = pod_dir
        @required_by = []
      end

      def required_by(specification, dependency)
        unless @required_by.empty? || dependency.requirement.satisfied_by?(required_version)
          # TODO add graph that shows which dependencies led to this.
          required_by = @required_by.map(&:first).join(', ')
          raise "#{specification} tries to activate `#{dependency}', " \
                "but already activated version `#{required_version}' by #{required_by}."
        end
        @required_by << [specification, dependency]
      end

      def dependency
        @required_by.inject(Dependency.new(name)) { |previous, (_, dep)| previous.merge(dep) }
      end

      def only_part_of_other_pod?
        @required_by.all? { |_, dep| dep.part_of_other_pod }
      end

      def name
        @pod_dir.basename.to_s
      end

      def spec_pathname
        @pod_dir + required_version.to_s + "#{name}.podspec"
      end

      def podspec
        Specification.from_podspec(spec_pathname)
      end

      # Return the first version that matches the current dependency.
      def required_version
        unless v = versions.find { |v| dependency.match?(name, v) }
          raise "Required version (#{dependency}) not found for `#{name}'."
        end
        v
      end

      def ==(other)
        self.class === other && name == other.name
      end

      def to_s
        "#<#{self.class.name} for `#{name}' with required version `#{required_version}'>"
      end
      alias_method :inspect, :to_s

      # Returns Pod::Version instances, for each version directory, sorted from
      # highest version to lowest.
      def versions
        @pod_dir.children.map { |v| Version.new(v.basename) }.sort.reverse
      end
    end
  end
end