package ru.myx.distro;

import java.util.Iterator;

import ru.myx.distro.prepare.ConsoleOutput;

public class OperationContext {

    public boolean okState = true;

    public ConsoleOutput console = null;

    public Iterator<String> arguments;
}