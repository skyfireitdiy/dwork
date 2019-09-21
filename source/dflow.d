module dwork.dflow;
import dwork.dtask;
import std.algorithm;
import std.exception;
import core.thread;

class dflow(T)
{
    private
    {
        dtask[string] tasks__;
    }
    void insert(in string name, dtask task)
    {
        tasks__[name] = task;
    }

    void add_deps(Range)(in string name, in Range deps)
    {
        enforce(name in tasks__);
        each!(s => s in tasks__)(deps);
        tasks__[name].deps.stableInsert(deps);
    }

    void add_deps(in string name, in string dep)
    {
        enforce(name in tasks__ && dep in tasks__);
        tasks__[name].deps.stableInsert(dep);
    }

    auto next()
    {
        import std.stdio;

        auto flt = filter!(k => tasks__[k].status == dtask_status.prepare
                && all!(d => tasks__[d].status == dtask_status.finished)(tasks__[k].deps[]))(
                tasks__.keys());

        string[] ret;
        each!(f => ret ~= f)(flt);
        each!((string k) { tasks__[k].status = dtask_status.running; })(ret);
        return ret;
    }

    ref dtask data(in string name)
    {
        return tasks__[name];
    }

    void finish(in string name)
    {
        enforce(name in tasks__ && tasks__[name].status == dtask_status.running);
        tasks__[name].status = dtask_status.finished;
    }

    void run()
    {
        auto runners = next();
        each!((string runner) {
            auto th = new Thread({
                if (tasks__[runner].run_task())
                {
                    finish(runner);
                    run();
                }
            });
            th.start();
            th.join();
        })(runners);
    }
}

unittest
{
    import std.stdio;
    import std.stdio;
    import std.conv;

    class AddTask : dtask
    {
        int a = 10;
        override bool run_task()
        {
            a *= 20;
            writeln("hello", a);
            return true;
        }
    }

    auto f = new dflow!AddTask;
    f.insert("add1", new AddTask);
    f.insert("add2", new AddTask);
    f.insert("add3", new AddTask);
    f.insert("add4", new AddTask);
    f.insert("add5", new AddTask);
    f.insert("add6", new AddTask);

    f.add_deps("add1", ["add2", "add3"]);
    f.add_deps("add3", "add4");
    f.add_deps("add4", ["add5", "add6"]);
    f.run();

    foreach (i; 1 .. 7)
    {
        writeln((cast(AddTask) f.data("add" ~ std.conv.to!string(i))).a);
    }

}
