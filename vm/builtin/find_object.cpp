// This is in a seperate file, even though it would normally be in system.cpp,
// because it uses a whole bunch of local classes and it's cleaner to have
// all that be in it's own file.

#include "vm/vm.hpp"

#include "gc/gc.hpp"
#include "gc/walker.hpp"
#include "objectmemory.hpp"

#include "builtin/object.hpp"
#include "builtin/array.hpp"
#include "builtin/symbol.hpp"
#include "builtin/module.hpp"

#include "builtin/system.hpp"

#include "object_utils.hpp"

namespace rubinius {
  class QueryCondition {
  public:
    virtual ~QueryCondition() { }
    virtual bool perform(STATE, Object* obj) = 0;
  };

  class AndCondition : public QueryCondition {
    QueryCondition* left_;
    QueryCondition* right_;

  public:
    AndCondition(QueryCondition* left, QueryCondition* right)
      : left_(left)
      , right_(right)
    {}

    virtual ~AndCondition() {
      delete left_;
      delete right_;
    }

    virtual bool perform(STATE, Object* obj) {
      return left_->perform(state, obj) && right_->perform(state, obj);
    }
  };

  class OrCondition : public QueryCondition {
    QueryCondition* left_;
    QueryCondition* right_;

  public:
    OrCondition(QueryCondition* left, QueryCondition* right)
      : left_(left)
      , right_(right)
    {}

    virtual ~OrCondition() {
      delete left_;
      delete right_;
    }

    virtual bool perform(STATE, Object* obj) {
      return left_->perform(state, obj) || right_->perform(state, obj);
    }
  };

  class KindofCondition : public QueryCondition {
    Module* mod_;

  public:
    KindofCondition(Module* mod)
      : mod_(mod)
    {}

    virtual bool perform(STATE, Object* obj) {
      return obj->kind_of_p(state, mod_);
    }
  };

  class ObjectIdCondition : public QueryCondition {
    Fixnum* id_;

  public:
    ObjectIdCondition(Fixnum* id)
      : id_(id)
    {}

    virtual bool perform(STATE, Object* obj) {
      return obj->has_id(state) && obj->id(state) == id_;
    }
  };

  class HasIvarCondition : public QueryCondition {
    Symbol* ivar_;

  public:
    HasIvarCondition(Symbol* ivar)
      : ivar_(ivar)
    {}

    virtual bool perform(STATE, Object* obj) {
      return !obj->get_ivar(state, ivar_)->nil_p();
    }
  };

  class HasMethodCondition : public QueryCondition {
    Symbol* name_;

  public:
    HasMethodCondition(Symbol* name)
      : name_(name)
    {}

    virtual bool perform(STATE, Object* obj) {
      return obj->respond_to(state, name_, Qtrue)->true_p();
    }
  };

  static QueryCondition* create_condition(STATE, Array* ary) {
    if(ary->size() < 2) return 0;

    Symbol* what = try_as<Symbol>(ary->get(state, 0));
    Object* arg = ary->get(state, 1);

    if(what == state->symbol("kind_of")) {
      if(Module* mod = try_as<Module>(arg)) {
        return new KindofCondition(mod);
      }
    } else if(what == state->symbol("object_id")) {
      if(Fixnum* id = try_as<Fixnum>(arg)) {
        return new ObjectIdCondition(id);
      }
    } else if(what == state->symbol("ivar")) {
      if(Symbol* ivar = try_as<Symbol>(arg)) {
        return new HasIvarCondition(ivar);
      }
    } else if(what == state->symbol("method")) {
      if(Symbol* method = try_as<Symbol>(arg)) {
        return new HasMethodCondition(method);
      }
    } else if(what == state->symbol("and") ||
              what == state->symbol("or")) {
      if(ary->size() != 3) return 0;

      QueryCondition* left = 0;
      QueryCondition* right = 0;

      if(Array* sub = try_as<Array>(arg)) {
        left = create_condition(state, sub);
      }

      if(!left) return 0;

      if(Array* sub = try_as<Array>(ary->get(state, 2))) {
        right = create_condition(state, sub);
      }

      if(!right) {
        delete left;
        return 0;
      }

      if(what == state->symbol("and")) {
        return new AndCondition(left, right);
      } else {
        return new OrCondition(left, right);
      }
    }

    return 0;
  }

  Object* System::vm_find_object(STATE, Array* arg, Object* callable,
                                 CallFrame* calling_environment)
  {
    ObjectMemory::GCInhibit inhibitor(state->om);

    // Support an aux mode, where callable is an array and we just append
    // objects to it rather than #call it.
    Array* ary = try_as<Array>(callable);

    Array* args = Array::create(state, 1);

    int total = 0;

    QueryCondition* condition = create_condition(state, arg);
    if(!condition) return Fixnum::from(0);

    ObjectWalker walker(state->om);
    GCData gc_data(state);

    // Seed it with the root objects.
    walker.seed(gc_data);

    Object* obj = walker.next();
    Object* ret = Qnil;

    while(obj) {
      if(condition->perform(state, obj)) {
        total++;

        if(ary) {
          ary->append(state, obj);
        } else {
          args->set(state, 0, obj);
          ret = callable->send(state, calling_environment, G(sym_call),
                               args, Qnil, false);
          if(!ret) break;
        }
      }

      obj = walker.next();
    }

    delete condition;

    if(!ret) return 0;

    return Integer::from(state, total);
  }
}
