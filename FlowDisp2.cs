using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Xml.Linq;

namespace TranslateXml
{
    class FlowDisp2
    {
        Dictionary<string, CommandInfo> commands;

        Dictionary<string, int> commandIds = new Dictionary<string, int>();
        Dictionary<string, int> eventIds = new Dictionary<string, int>();

        int nextCommandId = 1;
        int nextEventId = 1;


        public void Display()
        {
            XDocument doc = XDocument.Load("FlowConfig.xml");

            commands = doc.Root
                .Elements("command")
                .Select(cmd => new CommandInfo
                {
                    CommandName = (string)cmd.Attribute("CommandName"),
                    ClassName = (string)cmd.Attribute("ClassName"),

                    Events = cmd.Elements("event")
                        .Select(evt => new EventInfo
                        {
                            EventName = (string)evt.Attribute("EventName"),

                            Timer = evt.Element("timer") == null
                                ? (TimerInfo?)null
                                : new TimerInfo
                                {
                                    Time = (int)evt.Element("timer").Attribute("time")
                                },

                            Transitions = evt.Elements("transition")
                                .Select(tr => new TransitionInfo
                                {
                                    Result = (string)tr.Attribute("Result"),
                                    NextCommand = (string)tr.Attribute("NextCommand")
                                })
                                .ToList()
                        })
                        .ToList()
                })
                .ToDictionary(c => c.CommandName);


            StateDisp stateDisp = new StateDisp();
            StateDisp.Display();


            PrintCommand(
                "IDLE_STATE",
                "StartTransaction",
                "",
                true,
                new HashSet<string>());
        }

        void PrintCommand(
            string currentState,
            string commandName,
            string indent,
            bool isLast,
            HashSet<string> visited)
        {
            WriteTreeLine(
                indent,
                isLast ? "└─ " : "├─ ",
                $"C{GetCommandId(commandName):D3} {commandName}",
                ConsoleColor.Yellow);

            if (visited.Contains(commandName))
            {
                WriteTreeLine(
                    indent + (isLast ? "    " : "│   "),
                    "└─ ",
                    "(Loop)",
                    ConsoleColor.Red);
                return;
            }

            visited.Add(commandName);

            if (!commands.TryGetValue(commandName, out CommandInfo command))
                return;

            string childIndent = indent + (isLast ? "    " : "│   ");

            for (int i = 0; i < command.Events.Count; i++)
            {
                EventInfo evt = command.Events[i];
                bool eventLast = (i == command.Events.Count - 1);

                WriteTreeLine(
                    childIndent,
                    eventLast ? "└─ " : "├─ ",
                    $"E{GetEventId(evt.EventName):D3} {evt.EventName}",
                    ConsoleColor.Cyan);

                string eventIndent = childIndent + (eventLast ? "    " : "│   ");

                if (evt.Timer != null)
                {
                    bool timerLast = evt.Transitions.Count == 0;

                    WriteTreeLine(
                        eventIndent,
                        timerLast ? "└─ " : "├─ ",
                        $"Timer ({evt.Timer.Value.Time})",
                        ConsoleColor.Magenta);
                }

                for (int j = 0; j < evt.Transitions.Count; j++)
                {
                    TransitionInfo tr = evt.Transitions[j];
                    bool transitionLast = (j == evt.Transitions.Count - 1);

                    string nextState = StateDisp.GetNextState(
                        currentState,
                        evt.EventName,
                        tr.Result);

                    WriteTreeLine(
                        eventIndent,
                        transitionLast ? "└─ " : "├─ ",
                        $"[{tr.Result}] ({currentState} → {nextState})",
                        ConsoleColor.Green);

                    PrintCommand(
                        nextState,
                        tr.NextCommand,
                        eventIndent + (transitionLast ? "    " : "│   "),
                        true,
                        new HashSet<string>(visited));
                }
            }
        }

        void WriteTreeLine(
          string indent,
          string branch,
          string text,
          ConsoleColor color)
        {
            Console.Write(indent);
            Console.Write(branch);

            ConsoleColor oldColor = Console.ForegroundColor;
            Console.ForegroundColor = color;
            Console.WriteLine(text);
            Console.ForegroundColor = oldColor;
        }



        int GetCommandId(string commandName)
        {
            if (!commandIds.TryGetValue(commandName, out int id))
            {
                id = nextCommandId++;
                commandIds.Add(commandName, id);
            }

            return id;
        }

        int GetEventId(string eventName)
        {
            if (!eventIds.TryGetValue(eventName, out int id))
            {
                id = nextEventId++;
                eventIds.Add(eventName, id);
            }

            return id;
        }

    }


}
