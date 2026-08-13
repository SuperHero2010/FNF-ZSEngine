package options;

import options.Option;

class ScriptDebuggersSubState extends BaseOptionsMenu
{
    public function new()
    {
        title = Language.getPhrase('script_debuggers_menu', 'Script Debuggers');
        rpcTitle = 'Script Debuggers Menu';

        var option:Option = new Option('Lua Debugger',
            'If checked, enables the Lua Debugger, allowing you to debug Lua scripts in ZS Engine',
            'luaDebugger',
            BOOL);
        addOption(option);

        var option:Option = new Option('Haxe Debugger',
            'If checked, enables the Haxe Debugger, allowing you to debug the Haxe scripts in ZS Engine',
            'haxeDebugger',
            BOOL);
        addOption(option);

        /*
        var option:Option = new Option('ZS Debugger',
            'If checked, enables the ZS Debugger, allowing you to debug the ZS scripts in ZS Engine',
            'zsDebugger',
            BOOL);
        addOption(option);
        */

        super();
    }
}