-module(roadrunner_grpc_protobuf_wire).
-moduledoc false.

%% The few protobuf helpers the reflection tests write requests and read
%% responses with, taken from roadrunner's reflection tests.

-export([field/2, fields/1, values/2]).

field(Number, Value) ->
    [varint((Number bsl 3) bor 2), varint(iolist_size(Value)), Value].

varint(N) when N < 128 -> <<N>>;
varint(N) -> <<1:1, (N band 127):7, (varint(N bsr 7))/binary>>.

%% A message's fields in order, `{Number, Value}`: a length-delimited one's
%% bytes, a varint's value.
fields(<<>>) ->
    [];
fields(Bytes) ->
    {Key, Rest} = read_varint(Bytes, 0, 0),
    case Key band 7 of
        0 ->
            {Value, Rest1} = read_varint(Rest, 0, 0),
            [{Key bsr 3, Value} | fields(Rest1)];
        2 ->
            {Len, Rest1} = read_varint(Rest, 0, 0),
            <<Value:Len/binary, Rest2/binary>> = Rest1,
            [{Key bsr 3, Value} | fields(Rest2)]
    end.

%% The values of one field.
values(Number, Fields) ->
    [Value || {N, Value} <- Fields, N =:= Number].

read_varint(<<1:1, Low:7, Rest/binary>>, Shift, Acc) ->
    read_varint(Rest, Shift + 7, Acc bor (Low bsl Shift));
read_varint(<<0:1, Low:7, Rest/binary>>, Shift, Acc) ->
    {Acc bor (Low bsl Shift), Rest}.
