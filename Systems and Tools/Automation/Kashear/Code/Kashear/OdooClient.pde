import org.apache.xmlrpc.client.XmlRpcClient;
import org.apache.xmlrpc.client.XmlRpcClientConfigImpl;
import java.net.URL;
import java.util.List;
import java.util.Map;
import java.util.Arrays;
import java.util.Collections;
import java.util.LinkedHashMap;

public class OdooClient {
  private int uid;
  private XmlRpcClient objectClient;
  private boolean authenticated;
  private String dbName;

  OdooClient (String dbName) {
    this.dbName = dbName;

    try {
      auth ();
      authenticated = true;
    } 
    catch (Exception e) {
      println ("Error authenticating ", e);
    }
  }

  boolean isAuthenticated () {
    return authenticated;
  }

  // Authenticate once, save uid and objectClient for further calls
  public void auth() throws Exception {
    XmlRpcClient commonClient = getXmlRpcClient("/xmlrpc/2/common");
    uid = getUid(commonClient);
    objectClient = getXmlRpcClient("/xmlrpc/2/object");
  }

  private XmlRpcClient getXmlRpcClient(String endpoint) throws Exception {
    XmlRpcClientConfigImpl config = new XmlRpcClientConfigImpl();
    config.setServerURL(new URL(ODOO_URL + endpoint));

    // This enables support for extensions like nulls
    config.setEnabledForExtensions(true);

    XmlRpcClient client = new XmlRpcClient();
    client.setConfig(config);
    return client;
  }

  private int getUid(XmlRpcClient client) throws Exception {
    return (int) client.execute("authenticate", Arrays.asList(dbName, ODOO_USER, ODOO_PASS, Collections.emptyMap()));
  }

  // Get state of sale order by name
  public String getState(String orderName) throws Exception {
    if (objectClient == null) throw new IllegalStateException("Call auth() first.");

    List<Object> domain = new ArrayList<Object>();
    domain.add(Arrays.asList("name", "=", orderName));

    Map<String, Object> kwargs = new HashMap<String, Object>();
    kwargs.put("fields", Arrays.asList("state"));
    kwargs.put("limit", 1);

    Object[] results = (Object[]) objectClient.execute("execute_kw", Arrays.asList(
      dbName, uid, ODOO_PASS, 
      "sale.order", "search_read", 
      Arrays.asList(domain), 
      kwargs
      ));

    if (results.length > 0) {
      @SuppressWarnings("unchecked")
        Map<String, Object> record = (Map<String, Object>) results[0];
      return (String) record.get("state");
    }
    return null;
  }

  // Confirm sale order by name, returns true if success
  public boolean confirmOrder(String orderName) throws Exception {
    if (objectClient == null) throw new IllegalStateException("Call auth() first.");

    // Search for order ID by name
    List<Object> domain = new ArrayList<Object>();
    domain.add(Arrays.asList("name", "=", orderName));

    Object[] ids = (Object[]) objectClient.execute("execute_kw", Arrays.asList(
      dbName, uid, ODOO_PASS, 
      "sale.order", "search", 
      Arrays.asList(domain), 
      Collections.singletonMap("limit", 1)
      ));

    if (ids.length == 0) {
      System.err.println("Order not found: " + orderName);
      return false;
    }

    // Call action_confirm
    Object result = objectClient.execute("execute_kw", Arrays.asList(
      dbName, uid, ODOO_PASS, 
      "sale.order", "action_confirm", 
      Arrays.asList(Collections.singletonList(ids[0]))
      ));

    return Boolean.TRUE.equals(result);
  }

  // Create invoice for sale order by name, returns list of created invoice IDs
  public List<Integer> createInvoice(String orderName) throws Exception {
    if (objectClient == null) throw new IllegalStateException("Call auth() first.");

    String state = getState(orderName);
    if (!state.equals("sale")) {
      throw new IllegalStateException("Order " + orderName + " is not in 'sale' state (current: " + state + ")");
    }

    // Search for sale order ID by name
    List<Object> domain = new ArrayList<Object>();
    domain.add(Arrays.asList("name", "=", orderName));

    Object[] ids = (Object[]) objectClient.execute("execute_kw", Arrays.asList(
      dbName, uid, ODOO_PASS, 
      "sale.order", "search", 
      Arrays.asList(domain), 
      Collections.singletonMap("limit", 1)
      ));

    if (ids.length == 0) {
      throw new RuntimeException("Sale Order not found: " + orderName);
    }

    // Call action_invoice_create (no extra params)
    Object[] invoiceIds = (Object[]) objectClient.execute("execute_kw", Arrays.asList(
      dbName, uid, ODOO_PASS, 
      "sale.order", "action_invoice_create", 
      Arrays.asList(Collections.singletonList(ids[0]))
      ));

    List<Integer> result = new ArrayList<Integer>();
    for (Object obj : invoiceIds) {
      result.add((Integer) obj);
    }

    return result;
  }

  public LinkedHashMap<Integer, String> getOrderInvoices(String orderName) throws Exception {
    if (objectClient == null) {
      throw new IllegalStateException("Call auth() first.");
    }

    // Properly construct the domain filter as List<Object>
    List<Object> domain = new ArrayList<Object>();
    domain.add(Arrays.asList("origin", "=", orderName));

    // Keyword arguments for fields and options
    Map<String, Object> kwargs = new HashMap<String, Object>();
    kwargs.put("fields", Arrays.asList("id", "state"));
    kwargs.put("order", "id asc");
    kwargs.put("limit", 0);  // 0 means no limit

    // Call 'search_read'
    Object[] result = (Object[]) objectClient.execute("execute_kw", Arrays.asList(
      dbName, uid, ODOO_PASS, 
      "account.invoice", "search_read", 
      Arrays.asList(domain), 
      kwargs
      ));

    // Parse results
    LinkedHashMap<Integer, String> invoiceIdStateMap = new LinkedHashMap<Integer, String>();
    for (Object obj : result) {
      @SuppressWarnings("unchecked")
        Map<String, Object> record = (Map<String, Object>) obj;
      Integer id = (Integer) record.get("id");
      String state = (String) record.get("state");
      invoiceIdStateMap.put(id, state);
    }

    return invoiceIdStateMap;
  }

  public boolean validateInvoice(int invoiceId) throws Exception {
    if (objectClient == null) throw new IllegalStateException("Call auth() first.");

    try {
      // Call the method - ignore the return value, focus on exception to detect failure
      objectClient.execute("execute_kw", Arrays.asList(
        dbName, uid, ODOO_PASS, 
        "account.invoice", "action_invoice_open", 
        Arrays.asList(Collections.singletonList(invoiceId))
        ));
      // If no exception, consider success
      return true;
    } 
    catch (org.apache.xmlrpc.XmlRpcException e) {
      // You can inspect the error message for specific handling/logging
      System.err.println("Invoice validation failed: " + e.getMessage());
      return false;
    }
  }

  // Get Partner ID using partner code
  public Integer getPartnerId(String partnerCode) throws Exception {
    if (objectClient == null) throw new IllegalStateException("Call auth() first.");

    List<Object> domain = new ArrayList<Object>();
    domain.add(Arrays.asList("partner_code", "=", partnerCode));

    Object[] partnerIds = (Object[]) objectClient.execute("execute_kw", Arrays.asList(
      dbName, uid, ODOO_PASS, 
      "res.partner", "search", 
      Arrays.asList(domain), 
      Collections.singletonMap("limit", 1)
      ));

    if (partnerIds.length == 0) return null;

    if (partnerIds[0] instanceof Integer) {
      return (Integer) partnerIds[0];
    } else if (partnerIds[0] instanceof Number) {
      return ((Number) partnerIds[0]).intValue();
    } else {
      return null;
    }
  }
  // Get Current Balance using the helper method getPartnerId
  public Double getCurrentBalance(String partnerCode) throws Exception {
    if (objectClient == null) throw new IllegalStateException("Call auth() first.");

    // Step 1: Search partner ID by partner_code
    Integer partnerId = getPartnerId(partnerCode);
    if (partnerId == null) {
      System.err.println("Partner not found for code: " + partnerCode);
      return null;
    }

    // Step 2: Call the method get_current_balance
    Object result = objectClient.execute("execute_kw", Arrays.asList(
      dbName, uid, ODOO_PASS, 
      "res.partner", "get_current_balance", 
      Arrays.asList(Collections.singletonList(partnerId))
      ));

    // Step 3: Result is a Map<String, Object> with partner.id keys as strings
    if (result instanceof Map<?, ?>) {
      @SuppressWarnings("unchecked")
        Map<String, Object> mapResult = (Map<String, Object>) result;

      String key = String.valueOf(partnerId);
      Object balanceObj = mapResult.get(key);

      if (balanceObj instanceof Number) {
        return ((Number) balanceObj).doubleValue();
      } else if (balanceObj instanceof String) {
        try {
          return Double.parseDouble((String) balanceObj);
        } 
        catch (NumberFormatException e) {
          System.err.println("Cannot parse balance string: " + balanceObj);
          return null;
        }
      }
    }
    System.err.println("Unexpected result type or missing partner id in result");
    return null;
  }
}
