require File.dirname(__FILE__) + '/../spec_helper'

describe "A Match node" do
  relates "1 if /x/" do
    compile do |g|
      g.push_const :Rubinius
      g.find_const :Globals # FIX: find the other Globals, order flipped
      g.push_literal :$_ # REFACTOR - we use this block a lot
      g.send :[], 1

      g.memoize do
        g.push_const :Regexp
        g.push_literal "x"
        g.push 0
        g.send :new, 2
      end

      f = g.new_label
      t = g.new_label

      g.send :=~, 1
      g.gif f
      g.push 1
      g.goto t
      f.set!
      g.push :nil
      t.set!
    end
  end
end
