import 'dart:convert';
import 'dart:math';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show rootBundle, FilteringTextInputFormatter;
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(RestauranteBoaApp());
}

class RestauranteBoaApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gaveta',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
      ),
      themeMode: ThemeMode.system,
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gaveta'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => PedidoScreen()),
                  );
                },
                icon: Image.asset('assets/imagens/waiter.png',
                    width: 30, height: 30),
                label: Text('Fazer Pedido', style: TextStyle(fontSize: 20)),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => EditarPedidosScreen()),
                  );
                },
                icon: Image.asset('assets/imagens/pencil.png',
                    width: 30, height: 30),
                label: Text('Editar Pedidos', style: TextStyle(fontSize: 20)),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => FazerContaScreen()),
                  );
                },
                icon: Image.asset('assets/imagens/receipt.png',
                    width: 30, height: 30),
                label: Text('Fazer Conta', style: TextStyle(fontSize: 20)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PedidoScreen extends StatefulWidget {
  @override
  _PedidoScreenState createState() => _PedidoScreenState();
}

class _PedidoScreenState extends State<PedidoScreen> {
  List<dynamic> _pratos = [];
  String _numeroMesa = '';
  List<Map<String, dynamic>> _pratosSelecionados = [];

  @override
  void initState() {
    super.initState();
    _loadPratos();
  }

  Future<void> _loadPratos() async {
    final String response = await rootBundle.loadString('assets/pratos.json');
    setState(() {
      _pratos = json.decode(response);
    });
  }

  void _adicionarPrato(int index) {
    setState(() {
      final prato = _pratos[index];
      final pratoExistente = _pratosSelecionados.firstWhere(
        (p) => p['nome'] == prato['nome'],
        orElse: () => {},
      );
      if (pratoExistente.isNotEmpty) {
        pratoExistente['quantidade']++;
      } else {
        _pratosSelecionados.add({...prato, 'quantidade': 1});
      }
    });
  }

  void _removerPrato(int index) {
    setState(() {
      final prato = _pratosSelecionados[index];
      if (prato['quantidade'] > 1) {
        prato['quantidade']--;
      } else {
        _pratosSelecionados.removeAt(index);
      }
    });
  }

  Future<void> _finalizarPedido(BuildContext context) async {
    if (_numeroMesa.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, insira o número da mesa!')),
      );
      return;
    }

    if (_pratosSelecionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, selecione pelo menos um prato!')),
      );
      return;
    }

    final pedido = {
      'id': Random().nextInt(100000),
      'numero_mesa': _numeroMesa,
      'pratos': _pratosSelecionados.map((p) {
        return {
          'nome': p['nome'],
          'quantidade': p['quantidade'],
          'preco': p['preco']
        };
      }).toList(),
      'preco_total': _pratosSelecionados.fold(0.0, (total, prato) {
        return total + (prato['quantidade'] * prato['preco']);
      }),
    };

    print('Finalizando pedido: $pedido'); // Log de depuração

    final directory = await getApplicationDocumentsDirectory();
    final file =
        File('${directory.path}/pedido.json'); // Corrigido o caminho do arquivo

    List<Map<String, dynamic>> pedidos = [];
    if (await file.exists()) {
      final content = await file.readAsString();
      if (content.isNotEmpty) {
        pedidos = json.decode(content).cast<Map<String, dynamic>>();
      }
    }

    pedidos.add(pedido);

    await file.writeAsString(json.encode(pedidos),
        mode: FileMode.write); // Forçando overwrite
    print(
        'Pedido salvo no arquivo: ${pedidos.length} pedidos no total'); // Log de depuração

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Pedido finalizado e salvo!')),
    );

    // Limpar a seleção após finalizar o pedido
    setState(() {
      _numeroMesa = '';
      _pratosSelecionados.clear();
    });
  }

  String _getPratoImage(String nome) {
    switch (nome.toLowerCase()) {
      case 'sushi':
        return 'assets/imagens/sushi.png';
      case 'hamburguer':
        return 'assets/imagens/burger.png';
      case 'salada':
        return 'assets/imagens/salad.png';
      case 'pizza':
        return 'assets/imagens/pizza.png';
      default:
        return 'assets/imagens/default.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Fazer Pedido'),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: TextField(
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (value) {
                setState(() {
                  _numeroMesa = value;
                });
              },
              decoration: InputDecoration(
                labelText: 'Número da Mesa',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _pratos.length,
              itemBuilder: (context, index) {
                final prato = _pratos[index];
                final pratoSelecionado = _pratosSelecionados.firstWhere(
                  (p) => p['nome'] == prato['nome'],
                  orElse: () => {},
                );
                final quantidade = pratoSelecionado.isNotEmpty
                    ? pratoSelecionado['quantidade']
                    : 0;
                return ListTile(
                  leading: Image.asset(
                    _getPratoImage(prato['nome']),
                    width: 50,
                    height: 50,
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child:
                            Text('${prato['nome']} - Quantidade: $quantidade'),
                      ),
                    ],
                  ),
                  subtitle: Text('R\$ ${prato['preco']}'),
                  trailing: quantidade > 0
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.remove),
                              onPressed: () => _removerPrato(index),
                            ),
                            IconButton(
                              icon: Icon(Icons.add),
                              onPressed: () => _adicionarPrato(index),
                            ),
                          ],
                        )
                      : ElevatedButton(
                          onPressed: () => _adicionarPrato(index),
                          child: Text('Adicionar'),
                        ),
                );
              },
            ),
          ),
          ElevatedButton(
            onPressed: _pratosSelecionados.isEmpty
                ? null
                : () => _finalizarPedido(context),
            child: Text('Finalizar Pedido'),
          ),
        ],
      ),
    );
  }
}

class EditarPedidosScreen extends StatefulWidget {
  @override
  _EditarPedidosScreenState createState() => _EditarPedidosScreenState();
}

class _EditarPedidosScreenState extends State<EditarPedidosScreen> {
  List<Map<String, dynamic>> _pedidos = [];

  @override
  void initState() {
    super.initState();
    _loadPedidos();
  }

  Future<void> _loadPedidos() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/pedido.json');
    if (await file.exists()) {
      final content = await file.readAsString();
      if (content.isNotEmpty) {
        setState(() {
          _pedidos = json.decode(content).cast<Map<String, dynamic>>();
        });
      }
    }
  }

  Future<void> _excluirPedido(int index) async {
    setState(() {
      _pedidos.removeAt(index);
    });

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/pedido.json');
    await file.writeAsString(json.encode(_pedidos));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Editar Pedidos'),
      ),
      body: ListView.builder(
        itemCount: _pedidos.length,
        itemBuilder: (context, index) {
          final pedido = _pedidos[index];
          return ListTile(
            title: Text(
                'Mesa ${pedido['numero_mesa']} - R\$ ${pedido['preco_total']}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: (pedido['pratos'] as List)
                  .map<Widget>((prato) =>
                      Text('${prato['quantidade']}x ${prato['nome']}'))
                  .toList(),
            ),
            trailing: IconButton(
              icon: Icon(Icons.delete),
              onPressed: () => _excluirPedido(index),
            ),
          );
        },
      ),
    );
  }
}

class FazerContaScreen extends StatefulWidget {
  @override
  _FazerContaScreenState createState() => _FazerContaScreenState();
}

class _FazerContaScreenState extends State<FazerContaScreen> {
  List<Map<String, dynamic>> _pedidos = [];
  double _valorTotal = 0.0;

  @override
  void initState() {
    super.initState();
    _loadPedidos();
  }

  Future<void> _loadPedidos() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/pedido.json');
    if (await file.exists()) {
      final content = await file.readAsString();
      if (content.isNotEmpty) {
        setState(() {
          _pedidos = json.decode(content).cast<Map<String, dynamic>>();
          _valorTotal = _pedidos.fold(
            0.0,
            (total, pedido) => total + pedido['preco_total'],
          );
        });
      }
    }
  }

  Future<void> _limparPedidos() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/pedido.json');
    await file.writeAsString('');
    setState(() {
      _pedidos.clear();
      _valorTotal = 0.0;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Pedidos finalizados e apagados!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Fazer Conta'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _pedidos.length,
              itemBuilder: (context, index) {
                final pedido = _pedidos[index];
                return ListTile(
                  title: Text(
                      'Mesa ${pedido['numero_mesa']} - R\$ ${pedido['preco_total']}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: (pedido['pratos'] as List)
                        .map<Widget>((prato) =>
                            Text('${prato['quantidade']}x ${prato['nome']}'))
                        .toList(),
                  ),
                );
              },
            ),
          ),
          ListTile(
            title: Text(
              'Total:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: Text(
              'R\$ $_valorTotal',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            onPressed: _pedidos.isEmpty ? null : _limparPedidos,
            child: Text('Finalizar Conta'),
          ),
        ],
      ),
    );
  }
}
