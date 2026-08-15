package native;

#if cpp
@:buildXml('
<target id="haxe">
    <source name="native/include/FastArray.cpp" />
</target>
')
@:include("native/include/FastArray.cpp")
@:native("fast_array_concat_push")
extern function fastArrayConcatPush<T>(arr:Array<T>, items:Array<T>):Void;

class FastArray
{
    public static inline function concatPush<T>(arr:Array<T>, items:Array<T>):Void
    {
        if (items == null || items.length == 0) return;
        #if cpp
        fastArrayConcatPush(arr, items);
        #else
        arr = arr.concat(items);
        #end
    }
}
#else
class FastArray
{
    public static inline function concatPush<T>(arr:Array<T>, items:Array<T>):Void
    {
        if (items == null || items.length == 0) return;
        arr = arr.concat(items);
    }
}
#end