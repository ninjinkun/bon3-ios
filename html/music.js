var Shiki, main;
var __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) {
  for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }
  function ctor() { this.constructor = child; }
  ctor.prototype = parent.prototype;
  child.prototype = new ctor;
  child.__super__ = parent.prototype;
  return child;
};
Shiki = (function() {
  function Shiki(variable_name) {
    this.variable_name = variable_name;
    this.root = new Shiki.Operator('*');
    this.root.left = new Shiki.Operand.Variable(this.variable_name);
    this.root.right = new Shiki.Operand.Number(1);
  }
  Shiki.prototype.getFunction = function() {
    return eval(("(function(" + this.variable_name + "){return ") + this.getString() + ";})");
  };
  Shiki.prototype.getString = function() {
    return this.root.getString();
  };
  Shiki.prototype.step = function() {
    var after, before, i, node, _results;
    i = 0;
    before = this.root.getString();
    after = before;
    _results = [];
    while (i < 10 && before === after) {
      node = this.getRandomOperator(this.root);
      Shiki.choise([this.wrapNode, this.cutNode, this.bang]).apply(this, [node]);
      after = this.root.getString();
      _results.push(i++);
    }
    return _results;
  };
  Shiki.prototype.getRandomOperator = function(root) {
    var current, index;
    current = root;
    while (Math.random() < 0.3) {
      index = current.randomIndex();
      if (current[index].isOperator) {
        current = current[index];
      } else {
        return current;
      }
    }
    return current;
  };
  Shiki.prototype.getRandomNode = function(root) {
    var current;
    current = root;
    while (current.isOperator && Math.random() < 0.8) {
      current = current[current.randomIndex()];
    }
    return current;
  };
  Shiki.prototype.getRandomOperand = function(root) {
    var current;
    current = root;
    while (current.isOperator) {
      current = current[current.randomIndex()];
    }
    return current;
  };
  Shiki.prototype.wrapNode = function(node) {
    var index, lr, operator;
    index = node.randomIndex();
    operator = this.randomOperator();
    lr = [node[index], this.randomInstance()];
    if (Math.random() > 0.5) {
      lr = [lr[1], lr[0]];
    }
    operator.left = lr[0];
    operator.right = lr[1];
    return node[index] = operator;
  };
  Shiki.prototype.cutNode = function(node) {
    var child, index;
    index = node.randomIndex();
    child = this.getRandomNode(node[index]);
    return node[index] = child;
  };
  Shiki.prototype.bang = function(node) {
    return node.bang();
  };
  Shiki.prototype.changeValue = function(node) {
    return node[node.randomIndex()] = this.randomInstance();
  };
  Shiki.prototype.randomOperator = function() {
    var r;
    r = new Shiki.Operator(Shiki.choise(Shiki.Operator.operators));
    r.left = this.randomInstance();
    r.right = this.randomInstance();
    return r;
  };
  Shiki.prototype.randomInstance = function() {
    var rand;
    rand = Math.random();
    if (rand > 0.7) {
      return this.randomOperator();
    } else if (rand > 0.4) {
      return new Shiki.Operand.Number;
    } else {
      return new Shiki.Operand.Variable(this.variable_name);
    }
  };
  return Shiki;
})();
Shiki.choise = function(list) {
  return list[Math.floor(Math.random() * list.length)];
};
Shiki.Operator = (function() {
  function Operator(operator) {
    if (operator != null) {
      this.operator = operator;
    } else {
      this.bang();
    }
    this.left = new Shiki.Operand(0);
    this.right = new Shiki.Operand(0);
  }
  Operator.prototype.getString = function() {
    return "(" + [this.left.getString(), this.operator, this.right.getString()].join('') + ")";
  };
  Operator.prototype.bang = function() {
    this.operator = Shiki.choise(Shiki.Operator.operators);
    if (this.left) {
      this.left.bang();
    }
    if (this.right) {
      return this.right.bang();
    }
  };
  Operator.prototype.isOperator = true;
  Operator.prototype.randomIndex = function() {
    return Shiki.choise(['left', 'right']);
  };
  return Operator;
})();
Shiki.Operator.operators = '* % / + & | ^ << >>'.split(/\s+/);
Shiki.Operand = (function() {
  function Operand(value) {
    this.value = value;
  }
  Operand.prototype.getString = function() {
    return this.value;
  };
  Operand.prototype.isOperator = false;
  return Operand;
})();
Shiki.Operand.Variable = (function() {
  __extends(Variable, Shiki.Operand);
  function Variable() {
    Variable.__super__.constructor.apply(this, arguments);
  }
  Variable.prototype.bang = function() {};
  return Variable;
})();
Shiki.Operand.Number = (function() {
  __extends(Number, Shiki.Operand);
  function Number() {
    this.bang();
  }
  Number.prototype.bang = function() {
    return this.value = Math.floor(Math.random() * 10) + 1;
  };
  return Number;
})();
main = function(sources) {
  var current_func, i, indexes, setIndexes, setTracks, step_music, t, tracks;
  tracks = [];
  setTracks = function() {
    var t, _i, _ref, _results;
    tracks = [];
    _results = [];
    for (_i = 0, _ref = 8 - 1; 0 <= _ref ? _i <= _ref : _i >= _ref; 0 <= _ref ? _i++ : _i--) {
      t = new Shiki('t');
      t.step();
      t.step();
      _results.push(tracks.push(t));
    }
    return _results;
  };
  setTracks();
  indexes = [];
  setIndexes = function() {
    var i;
    return indexes = (function() {
      var _ref, _results;
      _results = [];
      for (i = 0, _ref = tracks.length * 2 - 1; 0 <= _ref ? i <= _ref : i >= _ref; 0 <= _ref ? i++ : i--) {
        _results.push(Math.floor((i / 2) % tracks.length));
      }
      return _results;
    })();
  };
  setIndexes();
  t = 0;
  i = 0;
  current_func = function(t) {
    return t;
  };
  step_music = function() {
    var track;
    i++;
    track = tracks[indexes[i % indexes.length]];
    current_func = track.getFunction();
    if (Math.random() < 0.05) {
      track.step();
      current_func = track.getFunction();
    }
    if (Math.random() < 0.1) {
      indexes[i % indexes.length] = Math.floor(Math.random() * tracks.length);
    }
    if (Math.random() < 0.1) {
      indexes[i % indexes.length] = indexes[(i + indexes.length - 1) % indexes.length];
    }
    if (i % indexes.length === indexes.length - 1) {
      if (Math.random() < 0.5 && indexes.length > 2) {
        return indexes = indexes.slice(0, indexes.length / 2);
      } else if (Math.random() < 0.5) {
        return indexes = indexes.concat(indexes);
      }
    }
  };
  return document.get_samples = function(size) {
    var cell, samples_i;
    samples_i = 0;
    cell = [];
    while (samples_i < size) {
      cell.push(Math.floor(current_func(t * 8000 / 44100) % 256));
      t++;
      samples_i++;
      if (t % 5512 === 0) {
        step_music();
      }
    }
    return JSON.stringify(cell);
  };
};
main();