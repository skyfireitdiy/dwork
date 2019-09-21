module dwork.dtask;
import std.container.rbtree;

enum dtask_status
{
    prepare,
    running,
    finished
}

class dtask
{
    RedBlackTree!string deps;
    dtask_status status;
    this()
    {
        deps = redBlackTree!string();
        status = dtask_status.prepare;
    }

    bool run_task()
    {
        return true;
    }
}
