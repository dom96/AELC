import strutils, strtabs, os

const
  stackLimit = 150

type
  TStack* = object
    list*: seq[int]
    
proc newStack(): TStack =
  result.list = @[]
   
proc push(Stack: var TStack, item: int) =
  if stack.list.len() < stackLimit:
    var nSeq: seq[int] = @[item]
    for i in items(Stack.list):
      nSeq.add(i)
    Stack.list = nSeq

proc pop(Stack: var TStack): int =
  if Stack.list.len() == 0:
    return 0
  
  result = Stack.list[0]
  Stack.list.delete(0)
  
proc get(Stack: var TStack): int =
  if Stack.list.len() == 0:
    return 0
  result = Stack.list[0]
  
# --- End of Stack code ---

var variables = newStringTable(modeCaseSensitive)
variables[$ord('1')] = $ord('d')
variables[$ord('2')] = $ord('o')
variables[$ord('3')] = $ord('m')
variables[$ord('4')] = $ord('9')
variables[$ord('5')] = $ord('6')

proc getStack(stack: TStack): string =
  result = ""
  # If there is still something in the stack, return it too.
  if stack.list.len() != 0:
    result.add("\nStack: [")
    for i in 0..stack.list.len()-1:
      result.add($stack.list[i])
      if i != stack.list.len()-1:
        result.add(", ")
      else:
        result.add("]")

proc interpret(code: string): string =
  result = ""

  var stack = newStack()

  var i = 0
  
  var number = "0"
  var whileLoopStarted = -1 # Char index of the '[', otherwise -1
  var recurseLimit = 500 # The number of times a while loop is allowed to loop.
  var nrLoops = 0 # The number of times the while loop, looped. :P
  
  while True:
    case code[i]:
    of '0'..'9':
      # Add the digit to the number string
      number.add(code[i])
    of '>':
      # Push the number to the stack
      try:
        stack.push(number.parseInt())
      except EOverflow:
        return "\x0305ERROR:\x03 Overflow"
      number = "0"
    of '<':
      # Removes the top most value
      discard stack.pop()
    of 'p':
      result.add($stack.pop())
    of '.':
      result.add(chr(stack.pop))
    of '+':
      var first = stack.pop()
      var second = stack.pop()
      try:
        stack.push(first + second)
      except EOverflow:
        return "\x0305ERROR:\x03 Overflow"
    of '-':
      var first = stack.pop()
      var second = stack.pop()
      try:
        stack.push(first - second)
      except EOverflow:
        return "\x0305ERROR:\x03 Overflow"
    of '*':
      var first = stack.pop()
      var second = stack.pop()
      stack.push(first * second)
    of '/':
      var first = stack.pop()
      var second = stack.pop()
      stack.push(first div second)
    of 'u':
      echo("Character: ")
      var user = stdin.readLine()
      stack.push(ord(user[0]))
    of 'i':
      echo("Number: ")
      var user = stdin.readLine()
      try:
        stack.push(user.parseInt())
      except:
        stack.push(0)
    of '(':
      # Pops a value and if the value is 1, evaluates code between ( and )
      var value = stack.pop()
      if value != 1:
        # Skip all code up to a ')'
        while True:
          if code[i] == ')' or code[i] == '\0':
            break
          else: inc(i)
    of '!':
      # Logical NOT, Pops a value, if the value is 0 pushes 1, if the value is 1 pushes 0
      var value = stack.pop()
      if value == 0: stack.push(1)
      else: stack.push(0)
    of '#':
      # Duplicates the topmost value
      stack.push(stack.get())
    of '{':
      while True:
        if code[i] == '}' or code[i] == '\0':
          break
        else: inc(i)
    of '=':
      var v1 = stack.pop()
      var v2 = stack.pop()
      if v1 == v2:
        stack.push(1)
      else:
        stack.push(0)
    of '[':
      whileLoopStarted = i
    of ']':
      if stack.pop() != 0 and whileLoopStarted != -1:
        if nrLoops > recurseLimit:
          # If the recursion limit get's reached, end the loop, and send whatever has been computed :P
          result.add("\nRecursion limit reached(Limit: " & $recurseLimit & ", Reached: " & $nrLoops & ")")
          
          var stackTrace = getStack(stack)
          if stackTrace != "": result.add(stackTrace)
          
          return result
          
        i = whileLoopStarted
        inc(nrLoops)
      else:
        # Reset the values
        whileLoopStarted = -1
        nrLoops = 0
    
    of '\"':
      # Each character between " and " will get pushed as an integer
      inc(i)
      while True:
        if code[i] == '\"' or code[i] == '\0':
          break
        else:
          stack.push(ord(code[i]))
        inc(i)
    
    of '^':
      # Pops two values, creates a variable with the second
      # value as the name and first value as the value of the variable
      var value = stack.pop()
      var name = stack.pop()
      variables[$name] = $value
    
    of 'g':
      # Pops a value, pushes the variables value specified by the value popped
      var name = stack.pop()
      if variables.hasKey($name):
        stack.push(variables[$name].parseInt())
      else:
        stack.push(0)
      
    of '\\':
      # Swaps the topmost values, [0, 1] -> [1, 0]
      var first = stack.pop()
      var second = stack.pop()
      stack.push(first)
      stack.push(second)
    
    
    of '\0':
      break
    else:
      #
    
    inc(i)
    
  var stackTrace = getStack(stack)
  if stackTrace != "": result.add(stackTrace)
    
when isMainModule:
  #echo(chr(43))
  #echo(interpret("70>2>+. 69>. 76>. 76>. 79>."))
  #echo(interpret("0>(70>.)72>."))
  #echo(interpret("1>!p"))
  #echo(interpret("1>2>3><p"))
  #echo(interpret("1>[#p 1>+ # 10> = ! ]"))
  #echo(interpret("1111111111111111111111111111111111>>>>>>>0>[]omgiwanttobreakit"))
  #echo(interpret("\"t\".\"e\".\"s\".\"t\"."))

  if os.paramCount() != 0:
    if os.paramStr(1) == "-h" or os.paramStr(1) == "--help":
      echo("ael                     Interpreter")
      echo("ael -h[--help]          This help message")
      echo("ael -a[--about]         About info")
    elif os.paramStr(1) == "-a" or os.paramStr(1) == "--about":
      echo("AEL Interpreter - (C) Mad Dog Software - Dominik Picheta(dom96)")
      echo("  This software may not be sold, without the authors permission.")
      
  else:
    echo(interpret(stdin.readLine()))

    
    
  # Possible Nimrod bug: " don't work in args
    
  #echo(interpret(os.paramStr(1)))
  
  